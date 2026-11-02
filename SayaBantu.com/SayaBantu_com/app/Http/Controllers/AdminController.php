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
        try {
            $admin = auth()->user();

            if (!$admin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin belum terautentikasi.',
                ], 401);
            }

            // Admin Daerah wajib memiliki wilayah
            if ($admin->role_id == 2 && !$admin->city_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akun Admin Daerah belum memiliki wilayah.',
                ], 403);
            }

            // Query dasar untuk semua statistik dan daftar mitra
            $baseQuery = mitra_profiles::query();

            // Batasi data berdasarkan kota Admin Daerah
            if ($admin->role_id == 2) {
                $baseQuery->whereHas('user', function ($q) use ($admin) {
                    $q->where('city_id', $admin->city_id);
                });
            }

            // Daftar mitra yang menunggu verifikasi
            $mitras = (clone $baseQuery)
                ->with([
                    'user:id,name,email,phone,address,photo_profile',
                ])
                ->where('is_verified', 0)
                ->latest()
                ->get();

            // Statistik sesuai wilayah admin
            $menungguCount = (clone $baseQuery)
                ->where('is_verified', 0)
                ->count();

            $disetujuiHariIni = (clone $baseQuery)
                ->where('is_verified', 1)
                ->whereDate('verified_at', today())
                ->count();

            $ditolakCount = (clone $baseQuery)
                ->where('is_verified', 2)
                ->count();

            // Pastikan seluruh field dokumen tersedia
            $mitras->transform(function ($mitra) {
                $arr = $mitra->toArray();

                $arr['verification_image'] = $mitra->verification_image;
                $arr['selfie_image']       = $mitra->selfie_image;
                $arr['certificate']        = $mitra->certificate;
                $arr['skill_photos']       = $mitra->skill_photos;

                $arr['gender']     = $mitra->gender;
                $arr['birth_date'] = $mitra->birth_date;
                $arr['city']       = $mitra->city;
                $arr['bio']        = $mitra->bio;
                $arr['skills']     = $mitra->skills;

                return $arr;
            });

            return response()->json([
                'success' => true,
                'message' => 'Daftar Mitra yang menunggu verifikasi.',
                'statistics' => [
                    'menunggu'           => $menungguCount,
                    'disetujui_hari_ini' => $disetujuiHariIni,
                    'ditolak'            => $ditolakCount,
                ],
                'data' => $mitras,
            ], 200);
        } catch (\Exception $e) {
            Log::error('AdminController@unverifiedMitra: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat daftar mitra.',
            ], 500);
        }
    }


    // =========================================================
    // VERIFIKASI / PENOLAKAN MITRA
    // =========================================================

    public function verifyMitra(Request $request, $id)
    {
        $request->validate([
            'action' => 'required|string|in:approve,reject',
        ]);

        $admin = auth()->user();

        if (!$admin) {
            return response()->json([
                'success' => false,
                'message' => 'Admin belum terautentikasi.',
            ], 401);
        }

        if ($admin->role_id == 2 && !$admin->city_id) {
            return response()->json([
                'success' => false,
                'message' => 'Akun Admin Daerah belum memiliki wilayah.',
            ], 403);
        }

        $mitraProfile = mitra_profiles::with('user')->find($id);

        if (!$mitraProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil Mitra tidak ditemukan!',
            ], 404);
        }

        // Validasi wilayah Admin Daerah
        if ($admin->role_id == 2) {
            if (
                !$mitraProfile->user ||
                $mitraProfile->user->city_id != $admin->city_id
            ) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Mitra ini bukan dari wilayah Anda.',
                ], 403);
            }
        }

        // Cegah verifikasi ulang
        if ($mitraProfile->is_verified != 0) {
            return response()->json([
                'success' => false,
                'message' => 'Pendaftaran mitra ini sudah diproses sebelumnya.',
            ], 400);
        }

        $adminId = $admin->id;
        $mitraName = $mitraProfile->user->name ?? 'Mitra';

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
        } else {
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
            'data'    => $mitraProfile->fresh('user'),
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
            // ============================================================
            // 1. VALIDASI ADMIN
            // ============================================================
            $admin = auth()->user();

            if (!$admin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized.',
                ], 401);
            }

            // Admin Daerah wajib memiliki city_id
            if ((int) $admin->role_id === 2 && !$admin->city_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin Daerah belum memiliki wilayah kota.',
                ], 403);
            }

            // ============================================================
            // 2. VALIDASI RENTANG TANGGAL
            // ============================================================
            $validated = $request->validate([
                'start_date' => 'nullable|date',
                'end_date'   => 'nullable|date|after_or_equal:start_date',
            ]);

            $startDate = $validated['start_date']
                ?? now()->startOfMonth()->toDateString();

            $endDate = $validated['end_date']
                ?? now()->endOfMonth()->toDateString();

            // ============================================================
            // 3. QUERY DATA PEMBAYARAN
            // ============================================================
            $paymentsQuery = DB::table('payments')
                ->join('jobs', 'payments.job_id', '=', 'jobs.id')
                ->select(
                    'payments.id',
                    'payments.reference_code',
                    'payments.job_id',
                    'jobs.tittle',
                    'payments.commission_amount',
                    'payments.created_at'
                )
                ->whereBetween('payments.created_at', [
                    $startDate . ' 00:00:00',
                    $endDate . ' 23:59:59',
                ]);

            // ============================================================
            // 4. PEMBATASAN DATA BERDASARKAN KOTA ADMIN
            // ============================================================
            if ((int) $admin->role_id === 2) {
                $paymentsQuery
                    ->join('users as mitra_users', 'jobs.mitra_id', '=', 'mitra_users.id')
                    ->where('mitra_users.city_id', $admin->city_id);
            }

            // ============================================================
            // 5. AMBIL DATA PEMBAYARAN
            // ============================================================
            $payments = $paymentsQuery
                ->orderBy('payments.created_at', 'asc')
                ->get();

            // ============================================================
            // 6. KELOMPOKKAN DATA BERDASARKAN TANGGAL
            // ============================================================
            $groupedPayments = $payments->groupBy(function ($payment) {
                return \Carbon\Carbon::parse(
                    $payment->created_at
                )->format('Y-m-d');
            });

            $dailyReports = $groupedPayments->map(function ($items, $date) {
                $carbonDate = \Carbon\Carbon::parse($date);

                return [
                    'date' => $date,

                    'day' => [
                        'Mon' => 'Senin',
                        'Tue' => 'Selasa',
                        'Wed' => 'Rabu',
                        'Thu' => 'Kamis',
                        'Fri' => 'Jumat',
                        'Sat' => 'Sabtu',
                        'Sun' => 'Minggu',
                    ][$carbonDate->format('D')],

                    'total_transactions' => $items->count(),

                    'total_commission' => $items->sum(
                        'commission_amount'
                    ),

                    'transactions' => $items->values()->map(function ($payment) {
                        return [
                            'id' => $payment->id,
                            'reference_code' => $payment->reference_code,
                            'job_id' => $payment->job_id,
                            'job_title' => $payment->tittle,
                            'commission_amount' => $payment->commission_amount,
                            'created_at' => $payment->created_at,
                        ];
                    }),
                ];
            })->values();

            // ============================================================
            // 7. HITUNG RINGKASAN LAPORAN
            // ============================================================
            $totalTransactions = $payments->count();

            $totalCommission = $payments->sum(
                'commission_amount'
            );

            // ============================================================
            // 8. RESPONSE
            // ============================================================
            return response()->json([
                'success' => true,
                'message' => 'Laporan harian berhasil diambil.',

                'summary' => [
                    'total_transactions' => $totalTransactions,
                    'total_commission' => $totalCommission,
                ],

                'period' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                ],

                'daily_reports' => $dailyReports,
            ], 200);
        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('Daily Report Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil laporan harian.',
                'error' => config('app.debug')
                    ? $e->getMessage()
                    : null,
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
            $admin = auth()->user();

            if (!$admin) {
                return response()->json(['success' => false, 'message' => 'Admin belum terautentikasi.'], 401);
            }

            if ($admin->role_id == 2 && !$admin->city_id) {
                return response()->json(['success' => false, 'message' => 'Akun Admin Daerah belum memiliki wilayah.'], 403);
            }

            // TAMBAHKAN 'city_id' di user, dan tambahkan relasi 'user.city'
            $query = mitra_profiles::with([
                'user:id,name,email,phone,address,photo_profile,city_id',
                'user.city:id,name' // <-- Memuat nama kota
            ])->where('is_verified', 1);

            if ($admin->role_id == 2) {
                $query->whereHas('user', function ($q) use ($admin) {
                    $q->where('city_id', $admin->city_id);
                });
            }

            $mitras = $query
                ->orderBy('verified_at', 'desc')
                ->get()
                ->map(function ($mitra) {
                    $user = $mitra->user;

                    $skillPhotos = [];
                    if (!empty($mitra->skill_photos)) {
                        if (is_string($mitra->skill_photos)) {
                            $decoded = json_decode($mitra->skill_photos, true);
                            if (is_array($decoded)) $skillPhotos = $decoded;
                        } elseif (is_array($mitra->skill_photos)) {
                            $skillPhotos = $mitra->skill_photos;
                        }
                    }

                    return [
                        'id'                  => $mitra->id,
                        'user_id'             => $mitra->user_id,
                        'name'                => $user->name ?? 'Tanpa Nama',
                        'email'               => $user->email ?? 'Tanpa Email',
                        'phone'               => $user->phone ?? '-',
                        'address'             => $user->address ?? '-',
                        'profile_photo'       => $user->photo_profile ?? null,

                        'gender'              => $mitra->gender,
                        'birth_date'          => $mitra->birth_date,
                        // TAMBAHKAN INI: Ambil nama kota dari relasi user.city
                        'city'                => $user->city ? $user->city->name : '-', 
                        'bio'                 => $mitra->bio,
                        'skills'              => $mitra->skills,
                        'category'            => $mitra->skills,

                        'certificate'         => $mitra->certificate,
                        'skill_photos'        => $skillPhotos,
                        'verification_image'  => $mitra->verification_image,
                        'selfie_image'        => $mitra->selfie_image,

                        'bank_name'           => $mitra->bank_name,
                        'bank_account_number' => $mitra->bank_account_number,
                        'bank_account_name'   => $mitra->bank_account_name,

                        'point'               => (int) ($mitra->point ?? 0),
                        'rating'              => (float) ($mitra->rating ?? 0),
                        'jobs_completed'      => (int) ($mitra->jobs_completed ?? 0),

                        'is_verified'         => (bool) $mitra->is_verified,
                        'verified_by'         => $mitra->verified_by,
                        'verified_at'         => $mitra->verified_at,
                        'created_at'          => $mitra->created_at,

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
            return response()->json(['success' => false, 'message' => 'Gagal memuat mitra terverifikasi.'], 500);
        }
    }

    // ADMIN — Reset PIN User
    public function resetUserPin($id)
    {
        $user = \App\Models\users::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan.'
            ], 404);
        }

        // Hapus PIN lama
        $user->update(['pin' => null]);

        ActivityLogger::log(
            auth()->id(),
            'Reset PIN User',
            'Admin mereset PIN user ' . $user->name,
            'lock_open',
            'Admin'
        );

        return response()->json([
            'success' => true,
            'message' => 'PIN user berhasil direset. User dapat membuat PIN baru.',
        ], 200);
    }
}