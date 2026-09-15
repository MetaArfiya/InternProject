<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\mitra_profiles;
use App\Models\users;
use App\Models\jobs;
use App\Helpers\ActivityLogger;

class AdminController extends Controller
{
    // =========================================================
    // MITRA BELUM DIVERIFIKASI
    // =========================================================

    public function unverifiedMitra()
    {
        // Ambil profil mitra + data user (untuk foto_profil & nama)
        $mitras = mitra_profiles::with([
                'user:id,name,email,phone,address,photo_profile',
            ])
            ->where('is_verified', 0)
            ->latest()
            ->get();

        // =====================================================
        // STATISTIK
        // =====================================================

        $menungguCount = mitra_profiles::where('is_verified', 0)->count();

        $disetujuiHariIni = mitra_profiles::where('is_verified', 1)
            ->whereDate('verified_at', today())
            ->count();

        $ditolakCount = mitra_profiles::where('is_verified', 2)->count();

        // =====================================================
        // PASTIKAN SEMUA FIELD GAMBAR ADA DI RESPONSE
        // =====================================================

        $mitras->transform(function ($mitra) {
            $arr = $mitra->toArray();

            // Field dokumen yang wajib ada
            $arr['verification_image'] = $mitra->verification_image;
            $arr['selfie_image']       = $mitra->selfie_image;
            $arr['certificate']        = $mitra->certificate;
            $arr['skill_photos']       = $mitra->skill_photos;

            // Field tambahan
            $arr['gender']    = $mitra->gender;
            $arr['birth_date'] = $mitra->birth_date;
            $arr['city']      = $mitra->city;
            $arr['bio']       = $mitra->bio;
            $arr['skills']    = $mitra->skills;

            return $arr;
        });

        return response()->json([
            'success' => true,

            'message' => 'Daftar Mitra yang menunggu verifikasi.',

            'statistics' => [
                'menunggu'            => $menungguCount,
                'disetujui_hari_ini'  => $disetujuiHariIni,
                'ditolak'             => $ditolakCount,
            ],

            'data' => $mitras,
        ], 200);
    }


    // =========================================================
    // VERIFIKASI / PENOLAKAN MITRA
    // =========================================================

    public function verifyMitra(Request $request, $id)
    {
        // VALIDASI
        $request->validate([
            'action' => 'required|string|in:approve,reject',
        ]);

        // ADMIN YANG LOGIN
        $adminId = auth()->id();

        if (!$adminId) {
            return response()->json([
                'success' => false,
                'message' => 'Admin belum terautentikasi.',
            ], 401);
        }

        // CARI PROFIL MITRA
        $mitraProfile = mitra_profiles::find($id);

        if (!$mitraProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil Mitra tidak ditemukan!',
            ], 404);
        }

        // AMBIL DATA USER MITRA
        $mitraUser = users::find($mitraProfile->user_id);
        $mitraName = $mitraUser?->name ?? 'Mitra';

        // APPROVE
        if ($request->action === 'approve') {
            $mitraProfile->update([
                'is_verified' => 1,
                'verified_by' => $adminId,
                'verified_at' => now(),
            ]);

            ActivityLogger::log(
                $adminId,
                'Mitra berhasil diverifikasi',
                'Admin memverifikasi pendaftaran mitra ' . $mitraName . '.',
                'verified',
                'Admin'
            );

            $message = 'Akun Mitra berhasil diverifikasi dan sekarang sudah aktif!';
        }

        // REJECT
        else {
            $mitraProfile->update([
                'is_verified' => 2,
                'verified_by' => $adminId,
                'verified_at' => now(),
            ]);

            ActivityLogger::log(
                $adminId,
                'Pendaftaran mitra ditolak',
                'Admin menolak pendaftaran mitra ' . $mitraName . '.',
                'cancel',
                'Admin'
            );

            $message = 'Pendaftaran berkas mitra telah ditolak oleh sistem.';
        }

        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $mitraProfile,
        ], 200);
    }


    // =========================================================
    // MODERASI KONTEN
    // =========================================================

    public function contentModeration()
    {
        $jobs = jobs::with('pelanggan')->latest()->get();

        $reportedCount = jobs::where('status', 'Dibatalkan')->count();

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil daftar moderasi konten.',
            'reported_alert' => $reportedCount
                . ' postingan telah ditangguhkan/dibatalkan oleh sistem.',
            'data' => $jobs,
        ], 200);
    }


    // =========================================================
    // MODERASI JOB
    // =========================================================

    public function moderateJob(Request $request, $id)
    {
        $request->validate([
            'action' => 'required|string|in:safe,suspend,delete',
        ]);

        $adminId = auth()->id();

        if (!$adminId) {
            return response()->json([
                'success' => false,
                'message' => 'Admin belum terautentikasi.',
            ], 401);
        }

        $job = jobs::find($id);

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Postingan tidak ditemukan!',
            ], 404);
        }

        // SAFE
        if ($request->action === 'safe') {
            $job->update([
                'is_verified' => 1,
                'verified_by' => $adminId,
            ]);

            ActivityLogger::log(
                $adminId,
                'Postingan berhasil dimoderasi',
                'Admin menyatakan postingan sebagai aman dan terverifikasi.',
                'flag',
                'Admin'
            );

            $message = 'Postingan berhasil ditandai sebagai aman (terverifikasi).';
        }

        // SUSPEND
        elseif ($request->action === 'suspend') {
            $job->update([
                'status' => 'Dibatalkan',
                'is_verified' => 0,
            ]);

            ActivityLogger::log(
                $adminId,
                'Postingan berhasil ditangguhkan',
                'Admin menangguhkan postingan dari sistem.',
                'cancel',
                'Admin'
            );

            $message = 'Postingan berhasil ditangguhkan.';
        }

        // DELETE
        else {
            $job->delete();

            ActivityLogger::log(
                $adminId,
                'Postingan berhasil dihapus',
                'Admin menghapus postingan secara permanen dari sistem.',
                'cancel',
                'Admin'
            );

            $message = 'Postingan berhasil dihapus secara permanen dari sistem.';
        }

        return response()->json([
            'success' => true,
            'message' => $message,
        ], 200);
    }


    // =========================================================
    // ADMIN — Laporan Harian
    // GET /admin/daily-report?period=week
    // =========================================================

    public function dailyReport(Request $request)
    {
        try {
            $period = $request->query('period', 'week');

            // Tentukan tanggal mulai
            $start = match ($period) {
                'today' => now()->startOfDay(),
                'month' => now()->startOfMonth(),
                default => now()->startOfWeek(),
            };

            // Query agregasi harian dari tabel payments
            $data = DB::table('payments')
                ->select(
                    DB::raw("DATE(created_at) as tanggal"),
                    DB::raw("DATE_FORMAT(created_at, '%a') as hari"),
                    DB::raw("COUNT(*) as total_transaksi"),
                    DB::raw("SUM(commission_amount) as total_komisi"),
                    DB::raw("COUNT(DISTINCT job_id) as total_pekerjaan")
                )
                ->where('created_at', '>=', $start)
                ->groupBy('tanggal', 'hari')
                ->orderBy('tanggal', 'asc')
                ->get();

            // Mapping nama hari ke Indonesia
            $hariMap = [
                'Mon' => 'Sen',
                'Tue' => 'Sel',
                'Wed' => 'Rab',
                'Thu' => 'Kam',
                'Fri' => 'Jum',
                'Sat' => 'Sab',
                'Sun' => 'Min',
            ];

            $formatted = $data->map(function ($item) use ($hariMap) {
                return [
                    'tanggal'      => $item->tanggal,
                    'day'          => $hariMap[$item->hari] ?? $item->hari,
                    'transactions' => (int) $item->total_transaksi,
                    'income'       => (float) $item->total_komisi,
                    'jobs'         => (int) $item->total_pekerjaan,
                ];
            });

            // Summary
            $totalTransaksi = $formatted->sum('transactions');
            $totalPekerjaan = $formatted->sum('jobs');
            $totalKomisi    = $formatted->sum('income');
            $rataHarian     = $formatted->count() > 0
                ? $totalKomisi / $formatted->count()
                : 0;

            return response()->json([
                'success' => true,
                'message' => 'Berhasil memuat laporan harian.',
                'period'  => $period,
                'summary' => [
                    'total_transaksi' => $totalTransaksi,
                    'total_pekerjaan' => $totalPekerjaan,
                    'total_komisi'    => $totalKomisi,
                    'rata_harian'     => $rataHarian,
                ],
                'data' => $formatted->values(),
            ], 200);

        } catch (\Exception $e) {
            Log::error('AdminController@dailyReport: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat laporan: ' . $e->getMessage(),
            ], 500);
        }
    }
    /**
 * =============================================================
 * ADMIN — Daftar Mitra Terverifikasi
 * GET /admin/verified-mitra
 * =============================================================
 */
    /**
 * =============================================================
 * ADMIN — Daftar Mitra Terverifikasi
 * GET /admin/verified-mitra
 * =============================================================
 */
    public function verifiedMitra()
    {
        try {
            $mitras = mitra_profiles::with([
                    'user:id,name,email,phone,address,photo_profile',
                ])
                ->where('is_verified', 1)
                ->orderBy('verified_at', 'desc')
                ->get()
                ->map(function ($mitra) {
                    $user = $mitra->user;

                    // skill_photos disimpan sebagai JSON di DB
                    $skillPhotos = [];
                    if (!empty($mitra->skill_photos)) {
                        if (is_string($mitra->skill_photos)) {
                            $decoded = json_decode($mitra->skill_photos, true);
                            if (is_array($decoded)) {
                                $skillPhotos = $decoded;
                            }
                        } elseif (is_array($mitra->skill_photos)) {
                            $skillPhotos = $mitra->skill_photos;
                        }
                    }

                    return [
                        'id'                  => $mitra->id,
                        'user_id'             => $mitra->user_id,

                        // Data user
                        'name'                => $user->name ?? 'Tanpa Nama',
                        'email'               => $user->email ?? 'Tanpa Email',
                        'phone'               => $user->phone ?? '-',
                        'address'             => $user->address ?? '-',
                        'profile_photo'       => $user->photo_profile ?? null,

                        // Identitas mitra
                        'gender'              => $mitra->gender,
                        'birth_date'          => $mitra->birth_date,
                        'city'                => $mitra->city,
                        'bio'                 => $mitra->bio,
                        'skills'              => $mitra->skills,
                        'category'            => $mitra->skills, // alias untuk frontend

                        // Berkas
                        'certificate'         => $mitra->certificate,
                        'skill_photos'        => $skillPhotos,
                        'verification_image'  => $mitra->verification_image,
                        'selfie_image'        => $mitra->selfie_image,

                        // Rekening bank
                        'bank_name'           => $mitra->bank_name,
                        'bank_account_number' => $mitra->bank_account_number,
                        'bank_account_name'   => $mitra->bank_account_name,

                        // Statistik
                        'point'               => (int) ($mitra->point ?? 0),
                        'rating'              => (float) ($mitra->rating ?? 0),
                        'jobs_completed'      => (int) ($mitra->jobs_completed ?? 0),

                        // Status verifikasi
                        'is_verified'         => (bool) $mitra->is_verified,
                        'verified_by'         => $mitra->verified_by,
                        'verified_at'         => $mitra->verified_at,
                        'created_at'          => $mitra->created_at,

                        // User lengkap (untuk kompatibilitas frontend)
                        'user'                => $user,
                    ];
                });

            return response()->json([
                'success' => true,
                'total'   => $mitras->count(),
                'data'    => $mitras,
            ], 200);

        } catch (\Exception $e) {
            Log::error('AdminController@verifiedMitra: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat mitra terverifikasi.',
            ], 500);
        }
    }
}