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

            // =====================================================
            // TENTUKAN TANGGAL MULAI
            // =====================================================

            $start = match ($period) {
                'today' => now()->startOfDay(),
                'month' => now()->startOfMonth(),
                default => now()->startOfWeek(),
            };

            // =====================================================
            // AMBIL DATA PAYMENT + JOB
            // =====================================================
            //
            // payments = sumber transaksi
            // jobs     = sumber nama pekerjaan
            // job_id   = penghubung payment dengan pekerjaan
            //

            $payments = DB::table('payments')
                ->leftJoin(
                    'jobs',
                    'payments.job_id',
                    '=',
                    'jobs.id'
                )
                ->select(
                    'payments.id as payment_id',
                    'payments.reference_code',
                    'payments.job_id',
                    'jobs.tittle as job_title',
                    'payments.commission_amount',
                    'payments.created_at'
                )
                ->where('payments.created_at', '>=', $start)
                ->orderBy('payments.created_at', 'asc')
                ->get();

            // =====================================================
            // GROUP BERDASARKAN TANGGAL
            // =====================================================

            $grouped = $payments->groupBy(function ($payment) {
                return date(
                    'Y-m-d',
                    strtotime($payment->created_at)
                );
            });

            // =====================================================
            // MAPPING HARI
            // =====================================================

            $hariMap = [
                'Mon' => 'Sen',
                'Tue' => 'Sel',
                'Wed' => 'Rab',
                'Thu' => 'Kam',
                'Fri' => 'Jum',
                'Sat' => 'Sab',
                'Sun' => 'Min',
            ];

            // =====================================================
            // MAPPING BULAN
            // =====================================================

            $bulanMap = [
                '01' => 'Januari',
                '02' => 'Februari',
                '03' => 'Maret',
                '04' => 'April',
                '05' => 'Mei',
                '06' => 'Juni',
                '07' => 'Juli',
                '08' => 'Agustus',
                '09' => 'September',
                '10' => 'Oktober',
                '11' => 'November',
                '12' => 'Desember',
            ];

            // =====================================================
            // FORMAT DATA HARIAN
            // =====================================================

            $formatted = $grouped->map(
                function ($dayPayments, $tanggal)
                use ($hariMap, $bulanMap) {

                    $firstPayment = $dayPayments->first();

                    // -------------------------------------------------
                    // HARI + TANGGAL LENGKAP
                    // Contoh:
                    // Sab, 26 September 2026
                    // -------------------------------------------------

                    $timestamp = strtotime($firstPayment->created_at);

                    $hariInggris = date('D', $timestamp);
                    $hariIndonesia = $hariMap[$hariInggris]
                        ?? $hariInggris;

                    $bulanAngka = date('m', $timestamp);
                    $bulanIndonesia = $bulanMap[$bulanAngka]
                        ?? $bulanAngka;

                    $tanggalLengkap =
                        $hariIndonesia
                        . ', '
                        . date('d', $timestamp)
                        . ' '
                        . $bulanIndonesia
                        . ' '
                        . date('Y', $timestamp);

                    // =================================================
                    // DETAIL TRANSAKSI
                    // =================================================
                    //
                    // Satu payment = satu transaksi.
                    //
                    // Contoh:
                    // 2 transaksi
                    // PAY-ABC123
                    // PAY-DEF456
                    //

                    $transactionDetails = $dayPayments
                        ->map(function ($payment) {

                            return [
                                'id' => (int) $payment->payment_id,

                                'reference_code' =>
                                !empty($payment->reference_code)
                                    ? $payment->reference_code
                                    : 'PAY-' . str_pad(
                                        (string) $payment->payment_id,
                                        4,
                                        '0',
                                        STR_PAD_LEFT
                                    ),
                            ];
                        })
                        ->values();

                    // =================================================
                    // DETAIL PEKERJAAN
                    // =================================================
                    //
                    // Job dihitung berdasarkan job_id unik.
                    //
                    // Contoh:
                    //
                    // PAY-001 -> JOB-001
                    // PAY-002 -> JOB-001
                    // PAY-003 -> JOB-002
                    //
                    // Hasil:
                    // 3 transaksi
                    // 2 pekerjaan
                    //
                    // JOB-001 hanya muncul satu kali.
                    //

                    $jobDetails = $dayPayments
                        ->filter(function ($payment) {
                            return !empty($payment->job_id);
                        })
                        ->unique('job_id')
                        ->map(function ($payment) {

                            return [
                                'id' => (int) $payment->job_id,

                                'code' =>
                                '#JOB-' . str_pad(
                                    (string) $payment->job_id,
                                    4,
                                    '0',
                                    STR_PAD_LEFT
                                ),

                                'title' =>
                                !empty($payment->job_title)
                                    ? $payment->job_title
                                    : 'Pekerjaan tanpa judul',
                            ];
                        })
                        ->values();

                    // =================================================
                    // DATA SATU BARIS
                    // =================================================

                    return [

                        // Tanggal database
                        'tanggal' => $tanggal,

                        // Hari + tanggal lengkap
                        'day' => $tanggalLengkap,

                        // -------------------------------------------------
                        // JUMLAH TRANSAKSI
                        // -------------------------------------------------

                        'transactions' =>
                        $transactionDetails->count(),

                        // Detail ID transaksi
                        'transaction_details' =>
                        $transactionDetails,

                        // -------------------------------------------------
                        // JUMLAH PEKERJAAN UNIK
                        // -------------------------------------------------

                        'jobs' =>
                        $jobDetails->count(),

                        // Detail pekerjaan
                        'job_details' =>
                        $jobDetails,

                        // -------------------------------------------------
                        // TOTAL KOMISI PADA TANGGAL TERSEBUT
                        // -------------------------------------------------

                        'income' =>
                        (float) $dayPayments->sum(
                            'commission_amount'
                        ),
                    ];
                }
            )->values();

            // =====================================================
            // SUMMARY KESELURUHAN
            // =====================================================

            $totalTransaksi =
                $formatted->sum('transactions');

            $totalPekerjaan =
                $formatted->sum('jobs');

            $totalKomisi =
                $formatted->sum('income');

            // Rata-rata komisi per hari yang memiliki transaksi
            $rataHarian =
                $formatted->count() > 0
                ? $totalKomisi / $formatted->count()
                : 0;

            // =====================================================
            // RESPONSE
            // =====================================================

            return response()->json([

                'success' => true,

                'message' =>
                'Berhasil memuat laporan harian.',

                'period' => $period,

                'summary' => [

                    'total_transaksi' =>
                    $totalTransaksi,

                    'total_pekerjaan' =>
                    $totalPekerjaan,

                    'total_komisi' =>
                    $totalKomisi,

                    'rata_harian' =>
                    $rataHarian,
                ],

                'data' =>
                $formatted,

            ], 200);
        } catch (\Exception $e) {

            Log::error(
                'AdminController@dailyReport: '
                    . $e->getMessage()
            );

            return response()->json([

                'success' => false,

                'message' =>
                'Gagal memuat laporan: '
                    . $e->getMessage(),

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
