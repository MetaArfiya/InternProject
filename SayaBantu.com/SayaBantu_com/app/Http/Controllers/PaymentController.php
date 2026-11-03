<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use App\Models\Payment;
use App\Models\jobs;
use App\Models\users;
use App\Models\mitra_profiles;
use App\Models\system_setting;
use App\Models\Wallet;
use App\Models\PlatformWallet;
use App\Providers\WalletService;
use App\Helpers\ActivityLogger;


class PaymentController extends Controller
{
    use \App\Http\Controllers\Concerns\EnforcesAdminCity;

    protected WalletService $wallet;

    public function __construct(WalletService $wallet)
    {
        $this->wallet = $wallet;
    }

    // =============================================================
    // PELANGGAN — Riwayat Pembayaran
    // GET /api/pelanggan/payments
    // =============================================================
    public function pelangganIndex()
    {
        try {
            $userId = auth()->id();

            $payments = Payment::with([
                'job:id,tittle,final_price',
                'mitra:id,name',
            ])
                ->where('pelanggan_id', $userId)
                ->latest()
                ->get();

            $totalPembayaran = (float) $payments->sum('total_paid');

            $totalKomisi = (float) $payments
                ->where('status', 'held')
                ->sum('total_paid');

            $wallet = $this->wallet->getOrCreate($userId);

            return response()->json([
                'success' => true,
                'summary' => [
                    'saldo_tersedia'   => (float) $wallet->balance,
                    'saldo_ditahan'    => (float) $wallet->held_balance,
                    'total_pembayaran' => $totalPembayaran,
                    'total_komisi'     => $totalKomisi,
                    'total_transaksi'  => $payments->count(),
                ],
                'data' => $payments,
            ], 200);
        } catch (\Exception $e) {
            Log::error('PaymentController@pelangganIndex: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Gagal memuat riwayat pembayaran.'], 500);
        }
    }

    // =============================================================
    // PELANGGAN — Detail Pembayaran
    // GET /api/pelanggan/payments/{id}
    // =============================================================
    public function showForPelanggan($id)
    {
        try {
            $payment = Payment::with(['job:id,tittle,final_price', 'mitra:id,name'])
                ->where('pelanggan_id', auth()->id())
                ->find($id);

            if (!$payment) {
                return response()->json(['success' => false, 'message' => 'Pembayaran tidak ditemukan.'], 404);
            }

            $wallet = $this->wallet->getOrCreate(auth()->id());

            return response()->json([
                'success' => true,
                'data' => [
                    'payment'       => $payment,
                    'amount_to_pay' => (float) $payment->total_paid,
                    'wallet' => [
                        'saldo_tersedia' => (float) $wallet->balance,
                        'saldo_ditahan'  => (float) $wallet->held_balance,
                        'cukup_saldo'    => $wallet->balance >= $payment->total_paid,
                    ],
                ],
            ], 200);
        } catch (\Exception $e) {
            Log::error('PaymentController@showForPelanggan: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Gagal memuat detail pembayaran.'], 500);
        }
    }

    // =============================================================
    // PELANGGAN — Bayar Job
    // =============================================================
    public function payJobWithBalance($id)
    {
        try {
            $payment = Payment::where('pelanggan_id', auth()->id())->find($id);

            if (!$payment) {
                return response()->json(['success' => false, 'message' => 'Pembayaran tidak ditemukan.'], 404);
            }

            if ($payment->status !== 'pending') {
                return response()->json(['success' => false, 'message' => 'Pembayaran tidak dalam status pending.'], 400);
            }

            $amount = (float) $payment->total_paid;

            $wallet = $this->wallet->getOrCreate(auth()->id());
            if ($wallet->balance < $amount) {
                return response()->json([
                    'success' => false,
                    'message' => 'Saldo tidak mencukupi. Silakan topup terlebih dahulu.',
                    'saldo_tersedia' => (float) $wallet->balance,
                    'kebutuhan'      => $amount,
                ], 400);
            }

            DB::transaction(function () use ($payment, $amount) {
                // Tahan saldo pelanggan
                $this->wallet->hold(auth()->id(), $amount, $payment->id);

                // Hitung dan isi mitra_earning
                $mitraEarning = $amount - (float) $payment->commission_amount;

                $payment->update([
                    'status'          => 'held',
                    'held_at'         => now(),
                    'payment_method'  => 'saldo',
                    'mitra_earning'   => $mitraEarning,
                ]);
            });

            ActivityLogger::log(auth()->id(), 'Pelanggan bayar job dengan saldo', 'Saldo ditahan untuk PAY-' . $payment->id, 'payment', 'Pelanggan');

            return response()->json([
                'success' => true,
                'message' => 'Saldo berhasil ditahan. Dana akan diteruskan ke saldo mitra setelah job selesai & di-ACC.',
                'data'    => $payment->fresh(),
            ], 200);
        } catch (\RuntimeException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 400);
        } catch (\Exception $e) {
            Log::error('PaymentController@payJobWithBalance: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Gagal memproses pembayaran: ' . $e->getMessage()], 500);
        }
    }

    // =============================================================
    // PELANGGAN — ACC Pekerjaan (OTOMATIS CAIR)
    // =============================================================

    public function acceptJobByPelanggan($id)
    {
        return response()->json([
            'success' => false,
            'message' => 'Persetujuan pekerjaan dilakukan melalui verifikasi bukti pekerjaan.',
            'endpoint' => '/api/jobs/{id}/verify-proof',
        ], 403);
    }


    // =============================================================
    // MITRA — Pendapatan (List)
    // =============================================================
    public function mitraIndex()
    {
        try {
            $userId = auth()->id();

            $payments = Payment::with(['job:id,tittle,final_price', 'pelanggan:id,name'])
                ->where('mitra_id', $userId)
                ->latest()
                ->get();

            $totalPendapatan = (float) $payments->where('status', 'released')->sum('mitra_earning');
            $totalPending = (float) $payments->where('status', 'held')->sum('mitra_earning');
            $totalKomisi = (float) $payments->whereIn('status', ['held', 'released'])->sum('commission_amount');

            $wallet = $this->wallet->getOrCreate($userId);

            return response()->json([
                'success' => true,
                'summary' => [
                    'saldo_tersedia'   => (float) $wallet->balance,
                    'saldo_ditahan'    => (float) $wallet->held_balance,
                    'total_pendapatan' => $totalPendapatan,
                    'total_pending'    => $totalPending,
                    'total_komisi'     => $totalKomisi,
                    'total_transaksi'  => $payments->count(),
                ],
                'data' => $payments,
            ], 200);
        } catch (\Exception $e) {
            Log::error('PaymentController@mitraIndex: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Gagal memuat pendapatan.'], 500);
        }
    }

    public function mitraMonthlyStats(Request $request)
    {
        try {
            $userId = auth()->id();

            $months = (int) $request->query('months', 6);

            // Batasi agar tidak ada request aneh
            if (!in_array($months, [6, 12], true)) {
                $months = 6;
            }

            $startDate = now()
                ->subMonths($months - 1)
                ->startOfMonth();

            /*
            * Hanya payment RELEASED yang dihitung sebagai
            * penghasilan nyata mitra.
            *
            * released_at digunakan sebagai tanggal penghasilan
            * karena dana baru benar-benar diterima mitra setelah
            * customer menyetujui pekerjaan.
            */
            $payments = Payment::query()
                ->where('mitra_id', $userId)
                ->where('status', 'released')
                ->whereNotNull('released_at')
                ->where('released_at', '>=', $startDate)
                ->orderBy('released_at')
                ->get([
                    'id',
                    'mitra_id',
                    'mitra_earning',
                    'released_at',
                ]);

            /*
            * Siapkan semua bulan terlebih dahulu supaya bulan
            * tanpa transaksi tetap muncul di grafik sebagai 0.
            */
            $monthly = [];

            for ($i = 0; $i < $months; $i++) {
                $date = $startDate->copy()->addMonths($i);

                $key = $date->format('Y-m');

                $monthly[$key] = [
                    'bulan' => $key,
                    'bulan_label' => $date->translatedFormat('M'),
                    'jumlah_pekerjaan' => 0,
                    'total_pendapatan' => 0,
                ];
            }

            /*
            * Masukkan payment released ke bulan masing-masing.
            */
            foreach ($payments as $payment) {
                $date = \Carbon\Carbon::parse($payment->released_at);
                $key = $date->format('Y-m');

                if (!isset($monthly[$key])) {
                    continue;
                }

                $monthly[$key]['jumlah_pekerjaan']++;

                $monthly[$key]['total_pendapatan'] +=
                    (float) ($payment->mitra_earning ?? 0);
            }

            $monthly = array_values($monthly);

            /*
            * Ringkasan periode.
            */
            $totalPendapatan = collect($monthly)
                ->sum('total_pendapatan');

            $totalPekerjaan = collect($monthly)
                ->sum('jumlah_pekerjaan');

            $rataRataPerBulan = $months > 0
                ? $totalPendapatan / $months
                : 0;

            return response()->json([
                'success' => true,

                'summary' => [
                    'total_pendapatan' => (float) $totalPendapatan,
                    'total_pekerjaan' => (int) $totalPekerjaan,
                    'rata_rata_per_bulan' => (float) $rataRataPerBulan,
                ],

                'monthly' => $monthly,
            ], 200);
        } catch (\Throwable $e) {

            Log::error('PaymentController@mitraMonthlyStats', [
                'user_id' => auth()->id(),
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat statistik penghasilan mitra.',
            ], 500);
        }
    }

    // (mitraMonthlyStats tetap sama seperti aslinya)

    // =============================================================
    // ADMIN — Semua Pembayaran
    // =============================================================
    // public function adminIndex()
    // {
    //     try {
    //         $payments = Payment::with([
    //                 'job:id,tittle,final_price',
    //                 'pelanggan:id,name,phone',
    //                 'mitra:id,name,phone',
    //             ])
    //             ->latest()
    //             ->get();

    //         $totalPembayaran = (float) $payments->whereIn('status', ['held', 'released'])->sum('total_paid');
    //         $totalKomisi = (float) $payments->whereIn('status', ['held', 'released'])->sum('commission_amount');
    //         $totalMitraEarn = (float) $payments->where('status', 'released')->sum('mitra_earning');

    //         // ✅ PERBAIKAN: Escrow dihitung dari total_paid (uang pelanggan yang ditahan)
    //         $totalEscrow = (float) $payments->where('status', 'held')->sum('total_paid');

    //         return response()->json([
    //             'success' => true,
    //             'summary' => [
    //                 'total_pembayaran' => $totalPembayaran,
    //                 'total_komisi'     => $totalKomisi,
    //                 'total_mitra_earn' => $totalMitraEarn,
    //                 'total_escrow'     => $totalEscrow,
    //                 'total_transaksi'  => $payments->count(),
    //             ],
    //             'data' => $payments,
    //         ], 200);

    //     } catch (\Exception $e) {
    //         Log::error('PaymentController@adminIndex: ' . $e->getMessage());
    //         return response()->json(['success' => false, 'message' => 'Gagal memuat pembayaran.'], 500);
    //     }
    // }


    // =============================================================
    // ADMIN — Semua Pembayaran
    // GET /api/admin/payments
    // =============================================================

    public function adminIndex(Request $request)
    {
        try {
            // Validasi filter tanggal
            $validated = $request->validate([
                'start_date' => 'nullable|date_format:Y-m-d',
                'end_date' => 'nullable|date_format:Y-m-d|after_or_equal:start_date',
            ]);

            $startDate = $validated['start_date'] ?? null;
            $endDate = $validated['end_date'] ?? null;

            $admin = auth()->user();
            if ($response = $this->missingAdminCityResponse($admin)) {
                return $response;
            }

            // Query pembayaran
            $query = Payment::with([
                'job:id,tittle,final_price',
                'pelanggan:id,name,phone',
                'mitra:id,name,phone',
            ]);

            // Filter wilayah untuk Admin Daerah
            // Berdasarkan domisili mitra
            if ($cityId = $this->adminCityId($admin)) {
                $query->whereIn('job_id', function ($subQuery) use ($admin) {
                    $subQuery->select('jobs.id')
                        ->from('jobs')
                        ->join(
                            'users as mitra_users',
                            'jobs.mitra_id',
                            '=',
                            'mitra_users.id'
                        )
                        ->where('mitra_users.city_id', $admin->city_id);
                });
            }

            // Filter tanggal mulai
            if ($startDate) {
                $query->where(
                    'created_at',
                    '>=',
                    $startDate . ' 00:00:00'
                );
            }

            // Filter tanggal selesai
            if ($endDate) {
                $query->where(
                    'created_at',
                    '<=',
                    $endDate . ' 23:59:59.999999'
                );
            }

            // Ambil pembayaran
            $payments = $query->latest()->get();

            // Hitung ringkasan
            $totalPembayaran = (float) $payments
                ->whereIn('status', ['held', 'released'])
                ->sum('total_paid');

            $totalKomisi = (float) $payments
                ->whereIn('status', ['held', 'released'])
                ->sum('commission_amount');

            $totalMitraEarn = (float) $payments
                ->where('status', 'released')
                ->sum('mitra_earning');

            $totalEscrow = (float) $payments
                ->where('status', 'held')
                ->sum('total_paid');

            return response()->json([
                'success' => true,

                'filter' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                ],

                'summary' => [
                    'total_pembayaran' => $totalPembayaran,
                    'total_komisi' => $totalKomisi,
                    'total_mitra_earn' => $totalMitraEarn,
                    'total_escrow' => $totalEscrow,
                    'total_transaksi' => $payments->count(),
                ],

                'data' => $payments,
            ], 200);
        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Throwable $e) {
            Log::error('PaymentController@adminIndex', [
                'admin_id' => auth()->id(),
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat pembayaran.',
            ], 500);
        }
    }



    // (showForAdmin tetap sama seperti aslinya)

    // =============================================================
    // ADMIN — Release Escrow (FALLBACK / MANUAL)
    // Biarkan dulu untuk berjaga-jaga
    // =============================================================
    // public function releaseToMitra($id)
    // {
    //     try {
    //         $payment = Payment::find($id);

    //         if (!$payment) {
    //             return response()->json(['success' => false, 'message' => 'Pembayaran tidak ditemukan.'], 404);
    //         }

    //         if ($payment->status !== 'held') {
    //             return response()->json(['success' => false, 'message' => 'Pembayaran tidak dalam status ditahan (held).'], 400);
    //         }

    //         $mitraEarning = (float) $payment->mitra_earning;
    //         $commission = (float) $payment->commission_amount;
    //         $totalPaid = (float) $payment->total_paid;

    //         DB::transaction(function () use ($payment, $mitraEarning, $commission, $totalPaid) {
    //             // Gunakan method baru
    //             $this->wallet->releasePayment(
    //                 $payment->pelanggan_id,
    //                 $payment->mitra_id,
    //                 $totalPaid,
    //                 $mitraEarning,
    //                 $commission,
    //                 $payment->id
    //             );

    //             $payment->update([
    //                 'status'      => 'released',
    //                 'released_at' => now(),
    //                 'customer_accepted_at' => $payment->customer_accepted_at ?? now(), // Paksa isi jika kosong
    //             ]);

    //             $job = jobs::find($payment->job_id);
    //             if ($job) {
    //                 $job->update(['status' => 'Selesai']);
    //             }
    //         });

    //         ActivityLogger::log(auth()->id(), 'Admin release dana ke mitra', 'Saldo mitra bertambah dari PAY-' . $payment->id, 'check_circle', 'Admin');

    //         return response()->json([
    //             'success' => true,
    //             'message' => 'Dana berhasil masuk ke saldo mitra.',
    //             'data'    => $payment->fresh(),
    //         ], 200);

    //     } catch (\Exception $e) {
    //         Log::error('PaymentController@releaseToMitra: ' . $e->getMessage());
    //         return response()->json(['success' => false, 'message' => 'Gagal melepas dana: ' . $e->getMessage()], 500);
    //     }
    // }

    public function releaseToMitra($id)
    {
        return response()->json([
            'success' => false,
            'message' => 'Pencairan dana dilakukan otomatis setelah pelanggan menyetujui hasil pekerjaan.',
        ], 403);
    }

    // (refund, superChart, superTopMitra tetap sama seperti aslinya)

    // =============================================================
    // SUPER ADMIN — Overview Platform
    // GET /api/superadmin/payments/overview
    // =============================================================
    public function superOverview()
    {
        try {
            $totalPembayaran   = (float) Payment::whereIn('status', ['held', 'released'])->sum('total_paid');
            $totalKomisi       = (float) Payment::whereIn('status', ['held', 'released'])->sum('commission_amount');
            $totalMitraEarning = (float) Payment::where('status', 'released')->sum('mitra_earning');
            $totalTransaksi    = Payment::count();

            $perStatus = Payment::select('status', DB::raw('COUNT(*) as total'))
                ->groupBy('status')
                ->pluck('total', 'status')
                ->toArray();

            // ✅ PERBAIKAN: Escrow dari total_paid
            $escrowAmount  = (float) Payment::where('status', 'held')->sum('total_paid');
            $releasedAmount = (float) Payment::where('status', 'released')->sum('mitra_earning');

            $totalSaldoUser = (float) Wallet::sum('balance');
            $totalSaldoHeld = (float) Wallet::sum('held_balance');

            // ✅ Tambahkan saldo platform
            $platformWallet = PlatformWallet::first();
            $saldoPlatform = $platformWallet ? (float) $platformWallet->balance : 0;

            return response()->json([
                'success' => true,
                'data' => [
                    'total_pembayaran'    => $totalPembayaran,
                    'total_komisi'        => $totalKomisi,
                    'total_mitra_earning' => $totalMitraEarning,
                    'total_transaksi'     => $totalTransaksi,
                    'escrow_amount'       => $escrowAmount,
                    'released_amount'     => $releasedAmount,
                    'total_saldo_user'    => $totalSaldoUser,
                    'total_saldo_held'    => $totalSaldoHeld,
                    'platform_balance'    => $saldoPlatform, // ✅ Field baru
                    'per_status'          => $perStatus,
                ],
            ], 200);
        } catch (\Exception $e) {
            Log::error('PaymentController@superOverview: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Gagal memuat overview: ' . $e->getMessage()], 500);
        }
    }

    // =============================================================
    // ADMIN — Detail Pembayaran
    // GET /api/admin/payments/{id}
    // =============================================================

    public function showForAdmin($id)
    {
        try {
            $admin = auth()->user();
            if ($response = $this->missingAdminCityResponse($admin)) {
                return $response;
            }

            $query = Payment::with([
                'job:id,tittle,description,final_price,location',
                'pelanggan:id,name,phone,email',
                'mitra:id,name,phone,email',
                'mitra.mitra_profiles',
            ]);

            // Filter wilayah Admin Daerah berdasarkan domisili mitra
            if ($cityId = $this->adminCityId($admin)) {
                $query->whereIn('job_id', function ($subQuery) use ($admin) {
                    $subQuery->select('jobs.id')
                        ->from('jobs')
                        ->join(
                            'users as mitra_users',
                            'jobs.mitra_id',
                            '=',
                            'mitra_users.id'
                        )
                        ->where('mitra_users.city_id', $admin->city_id);
                });
            }

            $payment = $query->find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan atau bukan wilayah Anda.',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'payment' => $payment,
                ],
            ], 200);
        } catch (\Throwable $e) {
            Log::error('PaymentController@showForAdmin', [
                'admin_id' => auth()->id(),
                'payment_id' => $id,
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat detail pembayaran.',
            ], 500);
        }
    }
}
