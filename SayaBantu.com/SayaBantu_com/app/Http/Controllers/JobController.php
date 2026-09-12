<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\jobs;
use App\Models\job_bids;
use App\Models\mitra_profiles;
use App\Models\users;
use App\Models\Payment;
use App\Notifications\BidAccepted;
use App\Notifications\NewBidReceived;
use App\Helpers\ActivityLogger;

class JobController extends Controller
{
    /**
     * =========================================================
     * DETAIL PEKERJAAN
     * =========================================================
     */
    public function show($id)
    {
        try {
            $job = jobs::withCount('bids')
                ->with([
                    'bids' => function ($query) {
                        $query->latest();
                    },
                    'bids.mitraProfile',
                    'bids.user'
                ])
                ->find($id);

            if (!$job) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pekerjaan tidak ditemukan.'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Detail pekerjaan berhasil diambil.',
                'data' => $job
            ], 200);

        } catch (\Exception $e) {
            Log::error("Error pada JobController@show: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * =========================================================
     * SEARCH PEKERJAAN
     * =========================================================
     */
    public function search(Request $request)
    {
        $keyword = $request->query('keyword');

        if (!$keyword) {
            $jobs = jobs::where('status', 'Mencari Mitra')->latest()->get();
            return response()->json([
                'success' => true,
                'message' => 'Menampilkan semua lowongan aktif.',
                'data' => $jobs
            ], 200);
        }

        $jobs = jobs::where('status', 'Mencari Mitra')
            ->where(function ($query) use ($keyword) {
                $query->where('tittle', 'LIKE', '%' . $keyword . '%')
                    ->orWhere('description', 'LIKE', '%' . $keyword . '%');
            })
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Hasil pencarian untuk: "' . $keyword . '"',
            'data' => $jobs
        ], 200);
    }

    /**
     * =========================================================
     * PEKERJAAN MILIK PELANGGAN
     * =========================================================
     */
    public function myJobs()
    {
        try {
            $pelangganId = auth()->id();

            $jobs = jobs::withCount('bids')
                ->with([
                    'mitra:id,name',
                    'pelanggan:id,name',
                ])
                ->where('pelanggan_id', $pelangganId)
                ->latest()
                ->get();

            $totalPosting = $jobs->count();
            $sedangBerjalan = $jobs->where('status', 'Sedang Dikerjakan')->count();
            $selesai = $jobs->where('status', 'Selesai')->count();

            return response()->json([
                'success' => true,
                'message' => 'Berhasil mengambil riwayat pekerjaan kamu.',
                'statistics' => [
                    'total_posting' => $totalPosting,
                    'sedang_berjalan' => $sedangBerjalan,
                    'selesai' => $selesai,
                ],
                'data' => $jobs,
            ], 200);

        } catch (\Exception $e) {
            Log::error('Error JobController@myJobs: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * PELANGGAN MEMBUAT POSTINGAN
     * =========================================================
     */
    public function store(Request $request)
    {
        Log::info('=== DEBUG UPLOAD JOB ===');
        Log::info('Has image: ' . ($request->hasFile('image') ? 'YES' : 'NO'));

        $validated = $request->validate([
            'tittle'          => 'required|string',
            'description'     => 'required|string',
            'location'        => 'required|string',
            'address_detail'  => 'nullable|string',
            'latitude'        => 'nullable|numeric',
            'longitude'       => 'nullable|numeric',
            'category'        => 'nullable|string',
            'initial_budget'  => 'required|numeric',
            'duration'        => 'required|string|max:50',
            'image'           => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        $imageUrl = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('jobs', 'public');
            $imageUrl = '/storage/' . $path;
        }

        $deskripsi = strtolower($request->description);
        $judul = strtolower($request->tittle);
        $minPrice = 75000;
        $maxPrice = 150000;
        $rekomendasiTeks = "Analisis Sistem: Deteksi jenis jasa harian / personal umum.";

        if (str_contains($deskripsi, 'walimurid') || str_contains($deskripsi, 'wali murid')) {
            $minPrice = 100000;
            $maxPrice = 150000;
            $rekomendasiTeks = "Analisis Sistem: Deteksi jasa wali murid sementara.";
        } elseif (str_contains($deskripsi, 'ac') || str_contains($judul, 'ac')) {
            $minPrice = 75000;
            $maxPrice = 180000;
            $rekomendasiTeks = "Analisis Sistem: Deteksi perawatan / cuci AC ringan.";
            if (str_contains($deskripsi, 'bocor') || str_contains($deskripsi, 'freon')) {
                $minPrice = 200000;
                $maxPrice = 400000;
                $rekomendasiTeks = "Analisis Sistem: Deteksi perbaikan AC bocor + tambah Freon.";
            }
        } elseif (str_contains($deskripsi, 'pompa') || str_contains($deskripsi, 'sanyo')) {
            $minPrice = 150000;
            $maxPrice = 350000;
            $rekomendasiTeks = "Analisis Sistem: Deteksi pengecekan mesin pompa air rusak.";
        }

        $aiRecommendation = $rekomendasiTeks . " Kisaran harga pasar: Rp " . number_format($minPrice, 0, ',', '.') . " - Rp " . number_format($maxPrice, 0, ',', '.') . ".";

        $validated['pelanggan_id'] = auth()->id();
        $validated['status'] = 'Mencari Mitra';
        $validated['ai_recommended_budget'] = $aiRecommendation;
        $validated['image_url'] = $imageUrl;

        if (isset($validated['address_detail'])) {
            $validated['location_description'] = $validated['address_detail'];
            unset($validated['address_detail']);
        }

        $job = jobs::create($validated);

        ActivityLogger::log(
            auth()->id(),
            'Pengguna membuat postingan',
            'Pengguna membuat postingan pekerjaan "' . $job->tittle . '".',
            'post_add',
            'Sistem'
        );

        return response()->json([
            'success' => true,
            'message' => 'Lowongan sukses diposting!',
            'data' => $job
        ], 201);
    }

    /**
     * =========================================================
     * DAFTAR PEKERJAAN UNTUK MITRA
     * =========================================================
     */
    public function availableJobs(Request $request)
    {
        $mitraId = auth()->id();
        $mitraProfile = mitra_profiles::where('user_id', $mitraId)->first();

        if (!$mitraProfile) {
            return response()->json([
                'success' => true,
                'message' => 'Profile Mitra tidak ditemukan.',
                'active_offers_count' => 0,
                'user_points' => 0,
                'data' => [],
                'jobs' => []
            ], 200);
        }

        $mitraSkills = [];
        $rawSkills = !empty($mitraProfile->skills) ? $mitraProfile->skills : ($mitraProfile->category ?? '');

        if (!empty($rawSkills)) {
            $mitraSkills = explode(',', $rawSkills);
            $mitraSkills = array_map(function ($skill) {
                $cleanSkill = preg_replace('/[\x{1F600}-\x{1F64F}\x{1F300}-\x{1F5FF}\x{1F680}-\x{1F6FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]/u', '', $skill);
                return strtolower(trim($cleanSkill));
            }, $mitraSkills);
            $mitraSkills = array_unique(array_filter($mitraSkills));
        }

        $query = jobs::withCount('bids')->where('status', 'Mencari Mitra');

        if (!empty($mitraSkills)) {
            $query->where(function ($q) use ($mitraSkills) {
                foreach ($mitraSkills as $skill) {
                    $q->orWhereRaw('LOWER(TRIM(category)) = ?', [$skill]);
                }
            });
        } else {
            $query->whereRaw('1 = 0');
        }

        $query->whereDoesntHave('bids', function ($bQuery) use ($mitraId) {
            $bQuery->where('mitra_id', $mitraId);
        });

        $jobs = $query->latest()->get();

        $activeOffersCount = job_bids::where('mitra_id', $mitraId)
            ->whereIn('status', ['Menunggu', 'Diterima Pelanggan'])
            ->count();

        $userPoints = $mitraProfile->point ?? 0;

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil daftar pekerjaan sesuai kemampuan Mitra.',
            'mitra_skills' => array_values($mitraSkills),
            'active_offers_count' => $activeOffersCount,
            'user_points' => $userPoints,
            'data' => $jobs,
            'jobs' => $jobs
        ], 200);
    }

    /**
     * =========================================================
     * PENAWARAN MILIK MITRA
     * =========================================================
     */
    public function myOffers(Request $request)
    {
        $userId = auth()->id();
        $profile = mitra_profiles::where('user_id', $userId)->first();
        $totalMitra = mitra_profiles::count();
        $higherPointsCount = mitra_profiles::where('point', '>', $profile ? $profile->point : 0)->count();
        $ranking = $higherPointsCount + 1;

        $myBids = job_bids::where('mitra_id', $userId)
            ->whereIn('status', ['Menunggu', 'Diterima Pelanggan'])
            ->with('job')
            ->latest()
            ->get();

        $formattedOffers = $myBids->map(function ($bid) {
            $queuePosition = job_bids::where('job_id', $bid->job_id)
                ->where('status', 'Menunggu')
                ->where('id', '<=', $bid->id)
                ->count();

            return [
                'id' => $bid->id,
                'job_id' => $bid->job_id,
                'tittle' => optional($bid->job)->tittle ?? 'Pekerjaan Tidak Diketahui',
                'price' => (float) ($bid->offered_price ?? 0),
                'queue_position' => $bid->status === 'Diterima Pelanggan' ? 1 : ($queuePosition ?: 1),
                'is_top' => ($bid->status === 'Diterima Pelanggan' || $queuePosition === 1),
                'status' => $bid->status ?? 'Menunggu'
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil daftar penawaran aktif.',
            'sidebar' => [
                'nama_mitra' => auth()->user()->name ?? 'Mitra',
                'total_poin' => $profile ? $profile->point : 0,
                'peringkat' => "Peringkat ke-" . $ranking . " dari " . $totalMitra . " mitra",
                'is_verified' => $profile ? (bool) $profile->is_verified : false,
            ],
            'data' => $formattedOffers
        ], 200);
    }

    /**
     * =========================================================
     * MITRA MEMBUAT PENAWARAN
     * =========================================================
     */
    public function applyJob(Request $request, $id)
    {
        $request->validate([
            'offered_price' => 'required|numeric|min:1000',
        ]);

        $mitraId = auth()->id();
        $mitraProfile = mitra_profiles::where('user_id', $mitraId)->first();

        // ✅ Gunakan truthy check, karena is_verified sudah boolean
        if (!$mitraProfile || !$mitraProfile->is_verified) {
            return response()->json([
                'success' => false,
                'message' => 'Akun anda belum diverifikasi oleh Admin. Tidak dapat mengajukkan penawaran.'
            ], 403);
        }

        $job = jobs::where('id', $id)->where('status', 'Mencari Mitra')->first();

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan atau sudah tidak menerima tawaran.'
            ], 404);
        }

        $alreadyBid = job_bids::where('job_id', $id)->where('mitra_id', $mitraId)->exists();

        if ($alreadyBid) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu sudah mengajukan penawaran untuk pekerjaan ini.'
            ], 400);
        }

        $currentPoint = $mitraProfile->point ?? 0;

        $bid = job_bids::create([
            'job_id' => $id,
            'mitra_id' => $mitraId,
            'offered_price' => $request->offered_price,
            'mitras_point_at_time' => $currentPoint,
            'status' => 'Menunggu'
        ]);

        ActivityLogger::log(
            auth()->id(),
            'Mitra membuat penawaran',
            'Mitra mengajukan penawaran sebesar Rp ' . number_format($bid->offered_price, 0, ',', '.') . ' untuk pekerjaan "' . $job->tittle . '".',
            'local_offer',
            'Mitra'
        );

        $pelanggan = users::find($job->pelanggan_id);
        if ($pelanggan) {
            $pelanggan->notify(new NewBidReceived($job, $bid));
        }

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengirimkan penawaran kerja!',
            'data' => $bid
        ], 201);
    }

    /**
     * =========================================================
     * PELANGGAN MENERIMA PENAWARAN MITRA
     * =========================================================
     * Set started_at saat pelanggan klik "Setujui"
     */
    public function acceptBid($bidId)
    {
        $selectedBid = job_bids::find($bidId);

        if (!$selectedBid) {
            return response()->json([
                'success' => false,
                'message' => 'Penawaran tidak ditemukan.'
            ], 404);
        }

        $job = jobs::find($selectedBid->job_id);

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.'
            ], 404);
        }

        if ($job->status !== 'Mencari Mitra') {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan ini sudah diambil atau sedang diproses oleh mitra lain.'
            ], 400);
        }

        if ($job->pelanggan_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk menerima penawaran ini.'
            ], 403);
        }

        // =====================================================
        // UPDATE JOB — SET started_at
        // =====================================================
        $job->update([
            'mitra_id' => $selectedBid->mitra_id,
            'final_price' => $selectedBid->offered_price,
            'status' => 'Sedang Dikerjakan',
            'started_at' => now(),
        ]);

        $selectedBid->update(['status' => 'Diterima Pelanggan']);

        job_bids::where('job_id', $job->id)
            ->where('id', '!=', $bidId)
            ->update(['status' => 'Ditolak']);

        $mitraUser = users::find($selectedBid->mitra_id);
        $mitraName = $mitraUser?->name ?? 'Mitra';

        ActivityLogger::log(
            auth()->id(),
            'Pelanggan menerima penawaran mitra',
            'Pelanggan menerima penawaran dari mitra ' . $mitraName . ' untuk pekerjaan "' . $job->tittle . '".',
            'check_circle',
            'Sistem'
        );

        if ($mitraUser) {
            $mitraUser->notify(new BidAccepted($job));
        }

        return response()->json([
            'success' => true,
            'message' => 'Selamat, Mitra berhasil dipilih! Pekerjaan sekarang berstatus Sedang Dikerjakan.',
            'data' => $job
        ], 200);
    }

    /**
     * =========================================================
     * PEKERJAAN SELESAI (manual oleh pelanggan)
     * =========================================================
     */
    public function completeJob(Request $request, $id)
    {
        $job = jobs::find($id);

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.'
            ], 404);
        }

        if ($job->pelanggan_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk menandai pekerjaan ini sebagai selesai.'
            ], 403);
        }

        $job->update(['status' => 'Selesai']);

        ActivityLogger::log(
            auth()->id(),
            'Pekerjaan selesai',
            'Pekerjaan "' . $job->tittle . '" telah ditandai sebagai selesai oleh pelanggan.',
            'check_circle',
            'Sistem'
        );

        return response()->json([
            'success' => true,
            'message' => 'Pekerjaan berhasil ditandai sebagai selesai.',
            'data' => $job
        ], 200);
    }

    /**
     * =========================================================
     * HERO RIGHT
     * =========================================================
     */
    public function getHeroData()
    {
        try {
            $latestJobWithBids = DB::table('jobs')
                ->where('status', 'Mencari Mitra')
                ->whereIn('id', function ($query) {
                    $query->select('job_id')->from('job_bids')->where('status', 'Menunggu');
                })
                ->latest()
                ->first();

            if (!$latestJobWithBids) {
                $activeMitraCount = DB::table('mitra_profiles')->where('is_verified', 1)->count();
                return response()->json([
                    'success' => true,
                    'data' => [
                        'title' => "BELUM ADA PENAWARAN",
                        'offers' => [],
                        'active_mitra_count' => $activeMitraCount,
                    ]
                ], 200);
            }

            $bids = DB::table('job_bids')
                ->leftJoin('users', 'job_bids.mitra_id', '=', 'users.id')
                ->leftJoin('mitra_profiles', 'job_bids.mitra_id', '=', 'mitra_profiles.user_id')
                ->select(
                    'job_bids.id',
                    'job_bids.offered_price',
                    'job_bids.mitras_point_at_time',
                    'users.name as user_name',
                    DB::raw('COALESCE(mitra_profiles.point, job_bids.mitras_point_at_time, 0) as total_point')
                )
                ->where('job_bids.job_id', $latestJobWithBids->id)
                ->where('job_bids.status', 'Menunggu')
                ->orderBy('total_point', 'desc')
                ->limit(3)
                ->get();

            $offers = $bids->map(function ($bid, $index) {
                $userName = $bid->user_name ?? 'Mitra';
                $words = explode(' ', trim($userName));
                $initials = (count($words) >= 2)
                    ? strtoupper(substr($words[0], 0, 1)) . substr($words[1], 0, 1)
                    : strtoupper(substr($userName, 0, 2));

                return [
                    'id' => $bid->id,
                    'active' => $index === 0,
                    'initials' => $initials,
                    'name' => $userName,
                    'rating' => '4.9',
                    'point' => $bid->total_point . ' poin',
                    'price' => 'Rp ' . number_format($bid->offered_price, 0, ',', '.'),
                    'badge' => $index === 0 ? 'ANTREAN #1' : null,
                ];
            });

            $title = "PENAWARAN MASUK — " . strtoupper($latestJobWithBids->tittle);
            $activeMitraCount = DB::table('mitra_profiles')->where('is_verified', 1)->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'title' => $title,
                    'offers' => $offers,
                    'active_mitra_count' => $activeMitraCount,
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * =========================================================
     * MITRA UPLOAD BUKTI SELESAI
     * =========================================================
     * Set completed_at ketika mitra upload bukti
     */
    public function uploadProof(Request $request, $id)
    {
        $job = jobs::find($id);

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.'
            ], 404);
        }

        if ($job->mitra_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda bukan mitra pekerjaan ini.'
            ], 403);
        }

        if ($job->status !== 'Sedang Dikerjakan') {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak dalam status sedang dikerjakan.'
            ], 400);
        }

        $request->validate([
            'photo' => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
            'note'  => 'nullable|string|max:500',
        ]);

        $path = $request->file('photo')->store('completion_proofs', 'public');
        $photoUrl = '/storage/' . $path;

        $job->update([
            'completion_photo_url'      => $photoUrl,
            'completion_submitted_at'   => now(),
            'completion_status'         => 'pending',
            'completion_verified_at'    => null,
            'completion_admin_note'     => $request->note ?? null,
            'status'                    => 'Menunggu Konfirmasi Selesai',
            'completed_at'              => now(),
        ]);

        ActivityLogger::log(
            auth()->id(),
            'Mitra upload bukti selesai',
            'Mitra mengupload bukti penyelesaian untuk pekerjaan "' . $job->tittle . '".',
            'upload_file',
            'Mitra'
        );

        return response()->json([
            'success' => true,
            'message' => 'Bukti berhasil diupload, menunggu konfirmasi pelanggan.',
            'data'    => $job->fresh()
        ], 200);
    }

    /**
     * =========================================================
     * PELANGGAN VERIFIKASI BUKTI + AUTO-CREATE PAYMENT
     * =========================================================
     * Model A: Komisi dipotong dari mitra.
     *  - total_paid    = job_amount                (pelanggan bayar sesuai deal)
     *  - mitra_earning = job_amount - commission   (mitra terima setelah dipotong)
     */
    public function verifyProof(Request $request, $id)
    {
        $job = jobs::find($id);

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.'
            ], 404);
        }

        if ($job->pelanggan_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda bukan pemilik pekerjaan ini.'
            ], 403);
        }

        if ($job->status !== 'Menunggu Konfirmasi Selesai') {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak dalam status menunggu konfirmasi.'
            ], 400);
        }

        $request->validate([
            'status' => 'required|in:approved,rejected',
            'note'   => 'nullable|string|max:500',
        ]);

        // =====================================================
        // UPDATE JOB
        // =====================================================
        $job->update([
            'completion_status'      => $request->status,
            'completion_verified_at' => now(),
            'completion_admin_note'  => $request->note ?? null,
            'status'                 => $request->status === 'approved' ? 'Selesai' : 'Sedang Dikerjakan',
        ]);

        // =====================================================
        // AUTO-CREATE PAYMENT & POINT (hanya jika approved)
        // =====================================================
        if ($request->status === 'approved') {

            // -------------------------------------------------
            // 1. Ambil setting dari system_settings
            // -------------------------------------------------
            $settings = DB::table('system_settings')->first();

            $commissionPercent = $settings
                ? (float) $settings->platform_commission_percent
                : 15.00;

            $pointsToAdd = $settings
                ? (int) $settings->points_on_completion
                : 10;

            // -------------------------------------------------
            // 2. Hitung nominal (MODEL A)
            // -------------------------------------------------
            $jobAmount        = (float) $job->final_price;
            $commissionAmount = round($jobAmount * ($commissionPercent / 100), 2);

            $totalPaid    = $jobAmount;                       // pelanggan bayar = nilai deal
            $mitraEarning = $jobAmount - $commissionAmount;   // mitra terima setelah dipotong

            // -------------------------------------------------
            // 3. Buat baris Payment (hindari duplikat)
            // -------------------------------------------------
            if (!Payment::where('job_id', $job->id)->exists()) {
                Payment::create([
                    'job_id'             => $job->id,
                    'pelanggan_id'       => $job->pelanggan_id,
                    'mitra_id'           => $job->mitra_id,
                    'job_amount'         => $jobAmount,
                    'commission_percent' => $commissionPercent,
                    'commission_amount'  => $commissionAmount,
                    'total_paid'         => $totalPaid,
                    'mitra_earning'      => $mitraEarning,
                    'status'             => 'pending',
                    'payment_method'     => null,
                    'reference_code'     => 'PAY-' . strtoupper(uniqid()),
                ]);
            }

            // -------------------------------------------------
            // 4. Tambah poin mitra
            // -------------------------------------------------
            $mitraProfile = mitra_profiles::where('user_id', $job->mitra_id)->first();
            if ($mitraProfile) {
                $mitraProfile->increment('point', $pointsToAdd);
            }
        }

        // =====================================================
        // LOG AKTIVITAS
        // =====================================================
        ActivityLogger::log(
            auth()->id(),
            'Pelanggan verifikasi bukti',
            'Pelanggan ' . ($request->status === 'approved' ? 'menyetujui' : 'menolak') . ' bukti pekerjaan "' . $job->tittle . '".',
            'check_circle',
            'Pelanggan'
        );

        return response()->json([
            'success' => true,
            'message' => 'Bukti berhasil diverifikasi.',
            'data'    => $job->fresh()
        ], 200);
    }
}