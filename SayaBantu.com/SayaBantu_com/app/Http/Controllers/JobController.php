<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\jobs;
use App\Models\job_bids;
use App\Models\mitra_profiles;
use App\Models\users;
use App\Notifications\BidAccepted;
use App\Notifications\NewBidReceived;
use App\Helpers\ActivityLogger;

class JobController extends Controller
{
    /**
     * =========================================================
     * DETAIL PEKERJAAN
     * =========================================================
     * Dipanggil oleh Flutter:
     * GET /api/jobs/{id}
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

            Log::error(
                "Error pada JobController@show: "
                . $e->getMessage()
            );

            return response()->json([
                'success' => false,
                'message' =>
                    'Terjadi kesalahan pada server: '
                    . $e->getMessage()
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

            $jobs = jobs::where(
                'status',
                'Mencari Mitra'
            )
                ->latest()
                ->get();

            return response()->json([
                'success' => true,
                'message' =>
                    'Menampilkan semua lowongan aktif.',
                'data' => $jobs
            ], 200);
        }

        $jobs = jobs::where(
            'status',
            'Mencari Mitra'
        )
            ->where(function ($query) use ($keyword) {

                $query->where(
                    'tittle',
                    'LIKE',
                    '%' . $keyword . '%'
                )
                ->orWhere(
                    'description',
                    'LIKE',
                    '%' . $keyword . '%'
                );
            })
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'message' =>
                'Hasil pencarian untuk: "'
                . $keyword
                . '"',
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
                ->where('pelanggan_id', $pelangganId)
                ->latest()
                ->get();

            $totalPosting = $jobs->count();

            $sedangBerjalan = $jobs->where(
                'status',
                'Sedang Dikerjakan'
            )->count();

            $selesai = $jobs->where(
                'status',
                'Selesai'
            )->count();

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

            Log::error(
                'Error JobController@myJobs: ' . $e->getMessage()
            );

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
     *
     * Flutter mengirim:
     *
     * tittle
     * description
     * initial_budget
     * location
     * address_detail
     * latitude
     * longitude
     * category
     * duration     <-- WAJIB (contoh: "1–2 Jam", "3–5 Jam", "1 Hari", dll.)
     * image        (opsional, multipart)
     */
    public function store(Request $request)
    {
        // =====================================================
        // DEBUG UPLOAD (opsional)
        // =====================================================
        Log::info('=== DEBUG UPLOAD JOB ===');
        Log::info('Has image: ' . ($request->hasFile('image') ? 'YES' : 'NO'));
        Log::info('Request files:', $request->allFiles());
        Log::info('Request data:', $request->except('image'));

        // =====================================================
        // VALIDASI
        // =====================================================
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

        // =====================================================
        // UPLOAD GAMBAR
        // =====================================================
        $imageUrl = null;
        if ($request->hasFile('image')) {
            Log::info('IMAGE FILE BERHASIL DITERIMA');
            $path = $request->file('image')->store('jobs', 'public');
            Log::info('IMAGE PATH: ' . $path);
            $imageUrl = '/storage/' . $path;
            Log::info('IMAGE URL: ' . $imageUrl);
        } else {
            Log::warning('IMAGE TIDAK DITERIMA OLEH SERVER');
        }

        // =====================================================
        // ANALISIS DESKRIPSI (untuk rekomendasi budget)
        // =====================================================
        $deskripsi = strtolower($request->description);
        $judul = strtolower($request->tittle);
        $minPrice = 75000;
        $maxPrice = 150000;
        $rekomendasiTeks = "Analisis Sistem: Deteksi jenis jasa harian / personal umum.";

        if (str_contains($deskripsi, 'walimurid') || str_contains($deskripsi, 'wali murid')) {
            $minPrice = 100000;
            $maxPrice = 150000;
            $rekomendasiTeks = "Analisis Sistem: Deteksi jasa wali murid sementara (ambil raport/pendampingan).";
        } elseif (str_contains($deskripsi, 'ac') || str_contains($judul, 'ac')) {
            $minPrice = 75000;
            $maxPrice = 180000;
            $rekomendasiTeks = "Analisis Sistem: Deteksi perawatan / cuci AC ringan.";
            if (str_contains($deskripsi, 'bocor') || str_contains($deskripsi, 'freon')) {
                $minPrice = 200000;
                $maxPrice = 400000;
                $rekomendasiTeks = "Analisis Sistem: Deteksi perbaikan AC bocor + tambah media Freon.";
            }
        } elseif (str_contains($deskripsi, 'pompa') || str_contains($deskripsi, 'sanyo')) {
            $minPrice = 150000;
            $maxPrice = 350000;
            $rekomendasiTeks = "Analisis Sistem: Deteksi pengecekan mesin pompa air rusak.";
        }

        $aiRecommendation = $rekomendasiTeks . " Kisaran harga pasar: Rp " . number_format($minPrice, 0, ',', '.') . " - Rp " . number_format($maxPrice, 0, ',', '.') . ".";

        // =====================================================
        // DATA TAMBAHAN
        // =====================================================
        $validated['pelanggan_id'] = auth()->id();
        $validated['status'] = 'Mencari Mitra';
        $validated['ai_recommended_budget'] = $aiRecommendation;
        $validated['is_verified'] = 0;
        $validated['verified_by'] = null;
        $validated['image_url'] = $imageUrl;

        // ══════════════════════════════════════════════════════════════
        // 🔁 MAPPING: address_detail (dari Flutter) → location_description (di DB)
        // ══════════════════════════════════════════════════════════════
        if (isset($validated['address_detail'])) {
            $validated['location_description'] = $validated['address_detail'];
            unset($validated['address_detail']); // hapus agar tidak error karena kolom tidak ada
        }

        // =====================================================
        // CREATE JOB
        // =====================================================
        $job = jobs::create($validated);

        // =====================================================
        // LOG AKTIVITAS
        // =====================================================
        ActivityLogger::log(
            auth()->id(),
            'Pengguna membuat postingan',
            'Pengguna membuat postingan pekerjaan "' . $job->tittle . '".',
            'post_add',
            'Sistem'
        );

        return response()->json([
            'success' => true,
            'message' => 'Lowongan sukses diposting dan masuk antrean moderasi!',
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

        // Ambil profile Mitra yang sedang login
        $mitraProfile = mitra_profiles::where('user_id', $mitraId)->first();

        // Jika profile Mitra tidak ditemukan
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

        /*
        |--------------------------------------------------------------------------
        | PARSE SKILLS / KATEGORI MITRA
        |--------------------------------------------------------------------------
        | Mendukung kategori utama dari gambar:
        | - Rumah & Bangunan
        | - Perbaikan & Perawatan
        | - Kebersihan
        | - Pindahan & Pengiriman
        | - Teknologi & Digital
        | - Kreatif & Desain
        | - Pendidikan & Les
        | - Jasa Personal
        | - Jasa Lainnya
        */

        $mitraSkills = [];

        // Ambil dari kolom 'skills' atau 'category' milik mitraProfile
        //$rawSkills = $mitraProfile->skills ?? $mitraProfile->category ?? '';
        $rawSkills = !empty($mitraProfile->skills)? $mitraProfile->skills: ($mitraProfile->category ?? '');

        if (!empty($rawSkills)) {
            // Jika tersimpan sebagai string dipisah koma
            $mitraSkills = explode(',', $rawSkills);

            $mitraSkills = array_map(function ($skill) {
                // Bersihkan emoji jika di DB tersimpan beserta emojinya (misal: "🏠 Rumah & Bangunan")
                $cleanSkill = preg_replace('/[\x{1F600}-\x{1F64F}\x{1F300}-\x{1F5FF}\x{1F680}-\x{1F6FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]/u', '', $skill);
                return strtolower(trim($cleanSkill));
            }, $mitraSkills);

            // Hilangkan nilai kosong dan duplikat
            $mitraSkills = array_unique(array_filter($mitraSkills));
        }

        /*
        |--------------------------------------------------------------------------
        | QUERY PEKERJAAN
        |--------------------------------------------------------------------------
        */

        $query = jobs::withCount('bids')
    ->where('status', 'Mencari Mitra');

        /*
        |--------------------------------------------------------------------------
        | FILTER BERDASARKAN KATEGORI MITRA
        |--------------------------------------------------------------------------
        */

        if (!empty($mitraSkills)) {
            $query->where(function ($q) use ($mitraSkills) {
                foreach ($mitraSkills as $skill) {
                    // Mencocokkan kolom category di tabel jobs dengan skill mitra (case-insensitive & trim)
                    $q->orWhereRaw('LOWER(TRIM(category)) = ?', [$skill]);
                }
            });
        } else {
            // Kalau Mitra belum memilih kategori/skills, jangan tampilkan pekerjaan apa pun
            $query->whereRaw('1 = 0');
        }

        /*
        |--------------------------------------------------------------------------
        | JANGAN TAMPILKAN JOB YANG SUDAH PERNAH DIBID MITRA INI
        |--------------------------------------------------------------------------
        */

        $query->whereDoesntHave('bids', function ($bQuery) use ($mitraId) {
            $bQuery->where('mitra_id', $mitraId);
        });

        /*
        |--------------------------------------------------------------------------
        | AMBIL DATA
        |--------------------------------------------------------------------------
        */

        $jobs = $query->latest()->get();

        /*
        |--------------------------------------------------------------------------
        | JUMLAH PENAWARAN AKTIF & POINT
        |--------------------------------------------------------------------------
        */

        $activeOffersCount = job_bids::where('mitra_id', $mitraId)
            ->whereIn('status', ['Menunggu', 'Diterima Pelanggan'])
            ->count();

        $userPoints = $mitraProfile->point ?? 0;

        /*
        |--------------------------------------------------------------------------
        | RESPONSE JSON
        |--------------------------------------------------------------------------
        */

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
                'job_id' => $bid->job_id, // <-- TAMBAHKAN INI
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
    public function applyJob(
        Request $request,
        $id
    ) {

        $request->validate([
            'offered_price' =>
                'required|numeric|min:1000',
        ]);


        $mitraId =
            auth()->id();


        $mitraProfile =
            mitra_profiles::where(
                'user_id',
                $mitraId
            )->first();


        if (
            !$mitraProfile ||
            $mitraProfile->is_verified !== 1
        ) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Akun anda belum diverifikasi oleh Admin. '
                    . 'Tidak dapat mengajukkan penawaran.'
            ], 403);
        }


        $job =
            jobs::where(
                'id',
                $id
            )
            ->where(
                'status',
                'Mencari Mitra'
            )
            ->first();


        if (!$job) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Pekerjaan tidak ditemukan atau sudah tidak menerima tawaran.'
            ], 404);
        }


        // =====================================================
        // CEK SUDAH BID
        // =====================================================

        $alreadyBid =
            job_bids::where(
                'job_id',
                $id
            )
            ->where(
                'mitra_id',
                $mitraId
            )
            ->exists();


        if ($alreadyBid) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Kamu sudah mengajukan penawaran untuk pekerjaan ini.'
            ], 400);
        }


        // =====================================================
        // POIN MITRA
        // =====================================================

        $currentPoint =
            $mitraProfile
                ? $mitraProfile->point
                : 0;


        // =====================================================
        // CREATE BID
        // =====================================================

        $bid =
            job_bids::create([

                'job_id' =>
                    $id,

                'mitra_id' =>
                    $mitraId,

                'offered_price' =>
                    $request->offered_price,

                'mitras_point_at_time' =>
                    $currentPoint,

                'status' =>
                    'Menunggu'
            ]);


        // =====================================================
        // LOG AKTIVITAS
        // =====================================================

        ActivityLogger::log(
            auth()->id(),
            'Mitra membuat penawaran',
            'Mitra mengajukan penawaran sebesar Rp '
                . number_format(
                    $bid->offered_price,
                    0,
                    ',',
                    '.'
                )
                . ' untuk pekerjaan "'
                . $job->tittle
                . '".',
            'local_offer',
            'Mitra'
        );


        // =====================================================
        // NOTIFIKASI PELANGGAN
        // =====================================================

        $pelanggan =
            users::find(
                $job->pelanggan_id
            );


        if ($pelanggan) {

            $pelanggan->notify(
                new NewBidReceived(
                    $job,
                    $bid
                )
            );
        }


        return response()->json([

            'success' => true,

            'message' =>
                'Berhasil mengirimkan penawaran kerja!',

            'data' =>
                $bid

        ], 201);
    }


    /**
     * =========================================================
     * PELANGGAN MENERIMA PENAWARAN MITRA
     * =========================================================
     */
    public function acceptBid($bidId)
    {
        $selectedBid =
            job_bids::find(
                $bidId
            );


        if (!$selectedBid) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Penawaran tidak ditemukan.'
            ], 404);
        }


        $job =
            jobs::find(
                $selectedBid->job_id
            );


        if (!$job) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Pekerjaan tidak ditemukan.'
            ], 404);
        }


        if (
            $job->status !==
            'Mencari Mitra'
        ) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Pekerjaan ini sudah diambil atau sedang diproses oleh mitra lain.'
            ], 400);
        }


        // =====================================================
        // PASTIKAN PEMILIK PEKERJAAN
        // =====================================================

        if (
            $job->pelanggan_id !==
            auth()->id()
        ) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Anda tidak memiliki izin untuk menerima penawaran ini.'
            ], 403);
        }


        // =====================================================
        // UPDATE JOB
        // =====================================================

        $job->update([

            'mitra_id' =>
                $selectedBid->mitra_id,

            'final_price' =>
                $selectedBid->offered_price,

            'status' =>
                'Sedang Dikerjakan'
        ]);


        // =====================================================
        // UPDATE BID
        // =====================================================

        $selectedBid->update([

            'status' =>
                'Diterima Pelanggan'
        ]);


        // =====================================================
        // TOLAK BID LAIN
        // =====================================================

        job_bids::where(
            'job_id',
            $job->id
        )
        ->where(
            'id',
            '!=',
            $bidId
        )
        ->update([

            'status' =>
                'Ditolak'
        ]);


        // =====================================================
        // LOG AKTIVITAS
        // =====================================================

        $mitraUser =
            users::find(
                $selectedBid->mitra_id
            );


        $mitraName =
            $mitraUser?->name
            ?? 'Mitra';


        ActivityLogger::log(
            auth()->id(),
            'Pelanggan menerima penawaran mitra',
            'Pelanggan menerima penawaran dari mitra '
                . $mitraName
                . ' untuk pekerjaan "'
                . $job->tittle
                . '".',
            'check_circle',
            'Sistem'
        );


        // =====================================================
        // NOTIFIKASI MITRA
        // =====================================================

        if ($mitraUser) {

            $mitraUser->notify(
                new BidAccepted(
                    $job
                )
            );
        }


        return response()->json([

            'success' => true,

            'message' =>
                'Selamat, Mitra berhasil dipilih! '
                . 'Pekerjaan sekarang berstatus Sedang Dikerjakan.',

            'data' =>
                $job

        ], 200);
    }


    /**
     * =========================================================
     * PEKERJAAN SELESAI
     * =========================================================
     */
    public function completeJob(
        Request $request,
        $id
    ) {

        $job =
            jobs::find(
                $id
            );


        if (!$job) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Pekerjaan tidak ditemukan.'
            ], 404);
        }


        if (
            $job->pelanggan_id !==
            auth()->id()
        ) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Anda tidak memiliki izin untuk menandai pekerjaan ini sebagai selesai.'
            ], 403);
        }


        $job->update([

            'status' =>
                'Selesai'
        ]);


        // =====================================================
        // LOG AKTIVITAS
        // =====================================================

        ActivityLogger::log(
            auth()->id(),
            'Pekerjaan selesai',
            'Pekerjaan "'
                . $job->tittle
                . '" telah ditandai sebagai selesai oleh pelanggan.',
            'check_circle',
            'Sistem'
        );


        return response()->json([

            'success' => true,

            'message' =>
                'Pekerjaan berhasil ditandai sebagai selesai.',

            'data' =>
                $job

        ], 200);
    }


    /**
     * =========================================================
     * HERO RIGHT
     * =========================================================
     * Dipanggil oleh Flutter:
     * GET /api/hero-right
     */
    public function getHeroData()
    {
        try {

            // =================================================
            // CARI JOB TERBARU YANG MEMILIKI BID
            // =================================================

            $latestJobWithBids =
                DB::table('jobs')
                    ->where(
                        'status',
                        'Mencari Mitra'
                    )
                    ->whereIn(
                        'id',
                        function ($query) {

                            $query->select(
                                'job_id'
                            )
                            ->from(
                                'job_bids'
                            )
                            ->where(
                                'status',
                                'Menunggu'
                            );
                        }
                    )
                    ->latest()
                    ->first();


            // =================================================
            // JIKA BELUM ADA BID
            // =================================================

            if (!$latestJobWithBids) {

                $activeMitraCount =
                    DB::table(
                        'mitra_profiles'
                    )
                    ->where(
                        'is_verified',
                        1
                    )
                    ->count();


                return response()->json([

                    'success' => true,

                    'data' => [

                        'title' =>
                            "BELUM ADA PENAWARAN",

                        'offers' =>
                            [],

                        'active_mitra_count' =>
                            $activeMitraCount,
                    ]

                ], 200);
            }


            // =================================================
            // AMBIL BID
            // =================================================

            $bids =
                DB::table(
                    'job_bids'
                )
                ->leftJoin(
                    'users',
                    'job_bids.mitra_id',
                    '=',
                    'users.id'
                )
                ->leftJoin(
                    'mitra_profiles',
                    'job_bids.mitra_id',
                    '=',
                    'mitra_profiles.user_id'
                )
                ->select(
                    'job_bids.id',
                    'job_bids.offered_price',
                    'job_bids.mitras_point_at_time',
                    'users.name as user_name',
                    DB::raw(
                        'COALESCE('
                        . 'mitra_profiles.point, '
                        . 'job_bids.mitras_point_at_time, '
                        . '0'
                        . ') as total_point'
                    )
                )
                ->where(
                    'job_bids.job_id',
                    $latestJobWithBids->id
                )
                ->where(
                    'job_bids.status',
                    'Menunggu'
                )
                ->orderBy(
                    'total_point',
                    'desc'
                )
                ->limit(3)
                ->get();


            // =================================================
            // FORMAT BID
            // =================================================

            $offers =
                $bids->map(
                    function (
                        $bid,
                        $index
                    ) {

                        $userName =
                            $bid->user_name
                            ?? 'Mitra';


                        $words =
                            explode(
                                ' ',
                                trim($userName)
                            );


                        $initials =
                            (count($words) >= 2)

                                ? strtoupper(
                                    substr(
                                        $words[0],
                                        0,
                                        1
                                    )
                                )
                                .
                                substr(
                                    $words[1],
                                    0,
                                    1
                                )

                                : strtoupper(
                                    substr(
                                        $userName,
                                        0,
                                        2
                                    )
                                );


                        return [

                            'id' =>
                                $bid->id,

                            'active' =>
                                $index === 0,

                            'initials' =>
                                $initials,

                            'name' =>
                                $userName,

                            'rating' =>
                                '4.9',

                            'point' =>
                                $bid->total_point
                                . ' poin',

                            'price' =>
                                'Rp '
                                . number_format(
                                    $bid->offered_price,
                                    0,
                                    ',',
                                    '.'
                                ),

                            'badge' =>
                                $index === 0
                                    ? 'ANTREAN #1'
                                    : null,
                        ];
                    }
                );


            // =================================================
            // TITLE
            // =================================================

            $title =
                "PENAWARAN MASUK — "
                . strtoupper(
                    $latestJobWithBids->tittle
                );


            // =================================================
            // JUMLAH MITRA AKTIF
            // =================================================

            $activeMitraCount =
                DB::table(
                    'mitra_profiles'
                )
                ->where(
                    'is_verified',
                    1
                )
                ->count();


            // =================================================
            // RESPONSE
            // =================================================

            return response()->json([

                'success' => true,

                'data' => [

                    'title' =>
                        $title,

                    'offers' =>
                        $offers,

                    'active_mitra_count' =>
                        $activeMitraCount,
                ]

            ], 200);

        } catch (\Exception $e) {

            return response()->json([

                'success' => false,

                'message' =>
                    'Error: '
                    . $e->getMessage()

            ], 500);
        }
    }

        /**
     * =========================================================
     * MITRA UPLOAD BUKTI SELESAI
     * =========================================================
     * POST /api/jobs/{id}/upload-proof
     * 
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function uploadProof(Request $request, $id)
    {
        // Cari job
        $job = jobs::find($id);

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.'
            ], 404);
        }

        // Hanya mitra yang sedang mengerjakan yang boleh upload
        if ($job->mitra_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda bukan mitra pekerjaan ini.'
            ], 403);
        }

        // Status harus 'Sedang Dikerjakan'
        if ($job->status !== 'Sedang Dikerjakan') {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak dalam status sedang dikerjakan.'
            ], 400);
        }

        // Validasi input
        $request->validate([
            'photo' => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
            'note'  => 'nullable|string|max:500',
        ]);

        // Upload foto
        $path = $request->file('photo')->store('completion_proofs', 'public');
        $photoUrl = '/storage/' . $path;

        // Update job
        $job->update([
            'completion_photo_url'      => $photoUrl,
            'completion_submitted_at'   => now(),
            'completion_status'         => 'pending',
            'completion_verified_at'    => null,
            'completion_admin_note'     => $request->note ?? null,
            'status'                    => 'Menunggu Konfirmasi Selesai',
        ]);

        // Log aktivitas
        ActivityLogger::log(
            auth()->id(),
            'Mitra upload bukti selesai',
            'Mitra mengupload bukti penyelesaian untuk pekerjaan "' . $job->tittle . '".',
            'upload_file',
            'Mitra'
        );

        // Notifikasi ke pelanggan (opsional, bisa diaktifkan jika sudah buat Notification)
        // $pelanggan = users::find($job->pelanggan_id);
        // if ($pelanggan) {
        //     $pelanggan->notify(new \App\Notifications\CompletionProofSubmitted($job));
        // }

        return response()->json([
            'success' => true,
            'message' => 'Bukti berhasil diupload, menunggu konfirmasi pelanggan.',
            'data'    => $job->fresh()
        ], 200);
    }

    /**
     * =========================================================
     * PELANGGAN VERIFIKASI BUKTI
     * =========================================================
     * POST /api/jobs/{id}/verify-proof
     * 
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyProof(Request $request, $id)
    {
        // Cari job
        $job = jobs::find($id);

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak ditemukan.'
            ], 404);
        }

        // Hanya pelanggan pemilik pekerjaan
        if ($job->pelanggan_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda bukan pemilik pekerjaan ini.'
            ], 403);
        }

        // Status harus 'Menunggu Konfirmasi Selesai'
        if ($job->status !== 'Menunggu Konfirmasi Selesai') {
            return response()->json([
                'success' => false,
                'message' => 'Pekerjaan tidak dalam status menunggu konfirmasi.'
            ], 400);
        }

        // Validasi input
        $request->validate([
            'status' => 'required|in:approved,rejected',
            'note'   => 'nullable|string|max:500',
        ]);

        // Update job
        $job->update([
            'completion_status'      => $request->status,
            'completion_verified_at' => now(),
            'completion_admin_note'  => $request->note ?? null,
            'status'                 => $request->status === 'approved' ? 'Selesai' : 'Sedang Dikerjakan',
        ]);

        // Jika disetujui, beri poin ke mitra (opsional)
        if ($request->status === 'approved') {
            // Ambil sistem setting untuk poin (pastikan model system_settings ada)
            // Jika belum ada, gunakan nilai default 10
            $pointsToAdd = 10; // atau ambil dari setting

            $mitraProfile = mitra_profiles::where('user_id', $job->mitra_id)->first();
            if ($mitraProfile) {
                $mitraProfile->increment('point', $pointsToAdd);
            }

            // Notifikasi ke mitra (opsional)
            // $mitra = users::find($job->mitra_id);
            // if ($mitra) {
            //     $mitra->notify(new \App\Notifications\JobCompleted($job));
            // }
        } else {
            // Notifikasi ke mitra jika ditolak (opsional)
            // $mitra = users::find($job->mitra_id);
            // if ($mitra) {
            //     $mitra->notify(new \App\Notifications\ProofRejected($job, $request->note));
            // }
        }

        // Log aktivitas
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