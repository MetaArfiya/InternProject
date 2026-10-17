<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\jobs;

class TrackingController extends Controller
{
    // =========================================================
    // MITRA — MULAI PERJALANAN
    // =========================================================

    public function start(Request $request, $id)
    {
        $mitraId = $request->user()->id;

        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);

        $job = jobs::where('id', $id)
            ->where('mitra_id', $mitraId)
            ->first();

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan atau bukan milik Anda.',
            ], 404);
        }

        $job->update([
            'mitra_lat'                 => $request->lat,
            'mitra_lng'                 => $request->lng,
            'mitra_location_updated_at' => now(),
            'tracking_status'           => 'menuju',
            'tracking_started_at'       => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Tracking dimulai.',
            'data'    => $this->trackingPayload($job),
        ]);
    }

    // =========================================================
    // MITRA — UPDATE POSISI (periodik)
    // =========================================================

    public function updateLocation(Request $request, $id)
    {
        $mitraId = $request->user()->id;

        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);

        $job = jobs::where('id', $id)
            ->where('mitra_id', $mitraId)
            ->first();

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.',
            ], 404);
        }

        // Hitung jarak & ETA dari lokasi tujuan (latitude/longitude)
        $distanceKm = null;
        $etaMinutes = null;

        $destLat = $job->latitude;
        $destLng = $job->longitude;

        if ($destLat !== null && $destLng !== null) {
            $distanceKm = $this->haversineKm(
                (float) $request->lat,
                (float) $request->lng,
                (float) $destLat,
                (float) $destLng,
            );

            // Asumsi kecepatan rata-rata 30 km/jam
            $etaMinutes = $distanceKm > 0
                ? (int) ceil(($distanceKm / 30) * 60)
                : 0;
        }

        $job->update([
            'mitra_lat'                 => $request->lat,
            'mitra_lng'                 => $request->lng,
            'mitra_location_updated_at' => now(),
            'distance_km'               => $distanceKm,
            'eta_minutes'               => $etaMinutes,
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->trackingPayload($job),
        ]);
    }

    // =========================================================
    // MITRA — UPDATE STATUS
    // =========================================================

    public function updateStatus(Request $request, $id)
    {
        $mitraId = $request->user()->id;

        $request->validate([
            'status' => 'required|in:menuju,sampai,dikerjakan,selesai',
        ]);

        $job = jobs::where('id', $id)
            ->where('mitra_id', $mitraId)
            ->first();

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.',
            ], 404);
        }

        $job->update(['tracking_status' => $request->status]);

        return response()->json([
            'success' => true,
            'message' => 'Status tracking diperbarui.',
            'data'    => $this->trackingPayload($job),
        ]);
    }

    // =========================================================
    // MITRA — HENTIKAN TRACKING
    // =========================================================

    public function stop(Request $request, $id)
    {
        $mitraId = $request->user()->id;

        $job = jobs::where('id', $id)
            ->where('mitra_id', $mitraId)
            ->first();

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.',
            ], 404);
        }

        $job->update(['tracking_status' => null]);

        return response()->json([
            'success' => true,
            'message' => 'Tracking dihentikan.',
        ]);
    }

    // =========================================================
    // PELANGGAN — AMBIL POSISI TERKINI
    // =========================================================

    public function getTracking(Request $request, $id)
    {
        $userId = $request->user()->id;

        $job = jobs::where('id', $id)
            ->where(function ($q) use ($userId) {
                // ✅ Boleh diakses pelanggan ATAU mitra dari job ini
                $q->where('pelanggan_id', $userId)
                  ->orWhere('mitra_id', $userId);
            })
            ->first();

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $this->trackingPayload($job),
        ]);
    }

    // =========================================================
    // HELPERS
    // =========================================================

    private function trackingPayload(jobs $job): array
    {
        return [
            'job_id'   => $job->id,
            'job_code' => '#JOB-' . str_pad((string) $job->id, 4, '0', STR_PAD_LEFT),
            'title'    => $job->tittle ?? 'Pekerjaan',

            // Tujuan — pakai kolom latitude/longitude yang sudah ada
            'destination' => [
                'lat'     => $job->latitude !== null ? (float) $job->latitude : null,
                'lng'     => $job->longitude !== null ? (float) $job->longitude : null,
                'address' => $job->location ?? $job->location_description ?? null,
            ],

            // Posisi mitra
            'mitra' => [
                'lat'        => $job->mitra_lat !== null ? (float) $job->mitra_lat : null,
                'lng'        => $job->mitra_lng !== null ? (float) $job->mitra_lng : null,
                'updated_at' => $job->mitra_location_updated_at,
            ],

            'distance_km' => $job->distance_km !== null ? (float) $job->distance_km : null,
            'eta_minutes' => $job->eta_minutes,
            'status'      => $job->tracking_status,
            'started_at'  => $job->tracking_started_at,
        ];
    }

    private function haversineKm(
        float $lat1,
        float $lng1,
        float $lat2,
        float $lng2,
    ): float {
        $R = 6371;

        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLng / 2) ** 2;

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return round($R * $c, 2);
    }
}