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
use App\Helpers\ActivityLogger;

class PaymentController extends Controller
{
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
            $totalKomisi     = (float) $payments->sum('commission_amount');

            return response()->json([
                'success' => true,
                'summary' => [
                    'total_pembayaran' => $totalPembayaran,
                    'total_komisi'     => $totalKomisi,
                    'total_transaksi'  => $payments->count(),
                ],
                'data' => $payments,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@pelangganIndex: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat riwayat pembayaran.',
            ], 500);
        }
    }

    // =============================================================
    // PELANGGAN — Detail Pembayaran + Info Rekening Platform
    // GET /api/pelanggan/payments/{id}
    // =============================================================
    public function showForPelanggan($id)
    {
        try {
            $payment = Payment::with(['job:id,tittle,final_price', 'mitra:id,name'])
                ->where('pelanggan_id', auth()->id())
                ->find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan.',
                ], 404);
            }

            $settings = system_setting::first();

            return response()->json([
                'success' => true,
                'data' => [
                    'payment' => $payment,
                    // Rekening tujuan transfer pelanggan
                    'transfer_to' => [
                        'bank_name'      => $settings->platform_bank_name ?? '-',
                        'account_number' => $settings->platform_bank_account_number ?? '-',
                        'account_name'   => $settings->platform_bank_account_name ?? '-',
                    ],
                    'amount_to_pay' => $payment->total_paid,
                ],
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@showForPelanggan: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat detail pembayaran.',
            ], 500);
        }
    }

    // =============================================================
    // PELANGGAN — Upload Bukti Transfer ke Platform
    // POST /api/pelanggan/payments/{id}/upload-proof
    // =============================================================
    public function uploadCustomerProof(Request $request, $id)
    {
        try {
            $payment = Payment::find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan.',
                ], 404);
            }

            if ($payment->pelanggan_id !== auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda bukan pemilik pembayaran ini.',
                ], 403);
            }

            if ($payment->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Status pembayaran tidak valid untuk upload bukti.',
                ], 400);
            }

            $request->validate([
                'proof'          => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
                'bank_name'      => 'required|string|max:100',
                'account_name'   => 'required|string|max:100',
                'note'           => 'nullable|string|max:500',
            ]);

            $path = $request->file('proof')->store('payment_proofs/customer', 'public');

            $payment->update([
                'customer_proof_url'         => '/storage/' . $path,
                'customer_proof_uploaded_at' => now(),
                'customer_bank_name'         => $request->bank_name,
                'customer_account_name'      => $request->account_name,
                'payment_method'             => 'transfer',
                'status'                     => 'waiting_verification',
                'admin_note'                 => $request->note,
            ]);

            ActivityLogger::log(
                auth()->id(),
                'Pelanggan upload bukti pembayaran',
                'Pelanggan upload bukti transfer untuk PAY-' . $payment->id,
                'upload_file',
                'Pelanggan'
            );

            return response()->json([
                'success' => true,
                'message' => 'Bukti pembayaran berhasil dikirim. Menunggu verifikasi admin.',
                'data'    => $payment->fresh(),
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('PaymentController@uploadCustomerProof: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengirim bukti: ' . $e->getMessage(),
            ], 500);
        }
    }

    // =============================================================
    // MITRA — Pendapatan (List)
    // GET /api/mitra/earnings
    // =============================================================
    public function mitraIndex()
    {
        try {
            $userId = auth()->id();

            $payments = Payment::with([
                    'job:id,tittle,final_price',
                    'pelanggan:id,name',
                ])
                ->where('mitra_id', $userId)
                ->latest()
                ->get();

            $totalPendapatan = (float) $payments
                ->where('status', 'settled')
                ->sum('mitra_earning');

            $totalPending = (float) $payments
                ->whereIn('status', ['pending', 'waiting_verification', 'paid'])
                ->sum('mitra_earning');

            $totalKomisi = (float) $payments->sum('commission_amount');

            return response()->json([
                'success' => true,
                'summary' => [
                    'total_pendapatan' => $totalPendapatan,
                    'total_pending'    => $totalPending,
                    'total_komisi'     => $totalKomisi,
                    'total_transaksi'  => $payments->count(),
                ],
                'data' => $payments,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@mitraIndex: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat pendapatan.',
            ], 500);
        }
    }

    // =============================================================
    // MITRA — Statistik Bulanan (untuk grafik & ringkasan)
    // GET /api/mitra/earnings/monthly?months=6
    // =============================================================
    public function mitraMonthlyStats(Request $request)
    {
        try {
            $userId = auth()->id();

            // Berapa bulan terakhir (default 6, max 24)
            $months = (int) $request->query('months', 6);
            if ($months < 1) $months = 6;
            if ($months > 24) $months = 24;

            $startDate = now()->subMonths($months - 1)->startOfMonth();

            // -------------------------------------------------
            // Data per bulan (group by YEAR + MONTH — anti strict mode)
            // -------------------------------------------------
            $monthly = Payment::select(
                    DB::raw("YEAR(created_at) as tahun"),
                    DB::raw("MONTH(created_at) as bulan_angka"),
                    DB::raw("COUNT(*) as jumlah_pekerjaan"),
                    DB::raw("SUM(mitra_earning) as total_pendapatan")
                )
                ->where('mitra_id', $userId)
                ->where('status', '!=', 'refunded')
                ->where('created_at', '>=', $startDate)
                ->groupBy('tahun', 'bulan_angka')
                ->orderBy('tahun', 'asc')
                ->orderBy('bulan_angka', 'asc')
                ->get();

            // -------------------------------------------------
            // Transform: tambah label bulan
            // -------------------------------------------------
            $namaBulan = [
                1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr',
                5 => 'Mei', 6 => 'Jun', 7 => 'Jul', 8 => 'Agu',
                9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des',
            ];

            $monthlyFormatted = $monthly->map(function ($row) use ($namaBulan) {
                $bulanLabel = $namaBulan[(int) $row->bulan_angka] ?? '?';
                return [
                    'bulan'            => sprintf('%04d-%02d', $row->tahun, $row->bulan_angka),
                    'bulan_label'      => $bulanLabel,
                    'jumlah_pekerjaan' => (int) $row->jumlah_pekerjaan,
                    'total_pendapatan' => (float) $row->total_pendapatan,
                ];
            });

            // -------------------------------------------------
            // Total keseluruhan
            // -------------------------------------------------
            $allPayments = Payment::where('mitra_id', $userId)
                ->where('status', '!=', 'refunded')
                ->get();

            $totalPendapatan   = (float) $allPayments->sum('mitra_earning');
            $totalPekerjaan    = $allPayments->count();
            $rataRataPerBulan  = $months > 0 ? $totalPendapatan / $months : 0;

            return response()->json([
                'success' => true,
                'summary' => [
                    'total_pendapatan'    => $totalPendapatan,
                    'total_pekerjaan'     => $totalPekerjaan,
                    'rata_rata_per_bulan' => round($rataRataPerBulan, 2),
                ],
                'monthly' => $monthlyFormatted,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@mitraMonthlyStats: ' . $e->getMessage());
            Log::error('Stack trace: ' . $e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat statistik bulanan: ' . $e->getMessage(),
            ], 500);
        }
    }

    // =============================================================
    // ADMIN — Semua Pembayaran
    // GET /api/admin/payments
    // =============================================================
    public function adminIndex()
    {
        try {
            $payments = Payment::with([
                    'job:id,tittle,final_price',
                    'pelanggan:id,name,phone',
                    'mitra:id,name,phone',
                ])
                ->latest()
                ->get();

            // Ambil rekening mitra untuk setiap payment
            $payments->transform(function ($p) {
                $mitraProfile = mitra_profiles::where('user_id', $p->mitra_id)->first();
                $arr = $p->toArray();
                $arr['mitra_bank'] = [
                    'bank_name'      => $mitraProfile->bank_name ?? '-',
                    'account_number' => $mitraProfile->bank_account_number ?? '-',
                    'account_name'   => $mitraProfile->bank_account_name ?? '-',
                ];
                return $arr;
            });

            $totalPembayaran = (float) $payments->sum('total_paid');
            $totalKomisi     = (float) $payments->sum('commission_amount');
            $totalMitraEarn  = (float) $payments->sum('mitra_earning');

            return response()->json([
                'success' => true,
                'summary' => [
                    'total_pembayaran' => $totalPembayaran,
                    'total_komisi'     => $totalKomisi,
                    'total_mitra_earn' => $totalMitraEarn,
                    'total_transaksi'  => $payments->count(),
                ],
                'data' => $payments,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@adminIndex: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat pembayaran.',
            ], 500);
        }
    }

    // =============================================================
    // ADMIN — Detail Pembayaran + Rekening Mitra
    // GET /api/admin/payments/{id}
    // =============================================================
    public function showForAdmin($id)
    {
        try {
            $payment = Payment::with([
                    'job',
                    'pelanggan:id,name,email,phone',
                    'mitra:id,name,email,phone',
                ])
                ->find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan.',
                ], 404);
            }

            $mitraProfile = mitra_profiles::where('user_id', $payment->mitra_id)->first();

            return response()->json([
                'success' => true,
                'data' => [
                    'payment' => $payment,
                    'transfer_to' => [
                        'bank_name'      => $mitraProfile->bank_name ?? '-',
                        'account_number' => $mitraProfile->bank_account_number ?? '-',
                        'account_name'   => $mitraProfile->bank_account_name ?? '-',
                    ],
                    'amount_to_transfer' => $payment->mitra_earning,
                ],
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@showForAdmin: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat detail pembayaran.',
            ], 500);
        }
    }

    // =============================================================
    // ADMIN — Verifikasi Bukti Pelanggan
    // PUT /api/admin/payments/{id}/verify
    // =============================================================
    public function verifyCustomerProof(Request $request, $id)
    {
        try {
            $payment = Payment::find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan.',
                ], 404);
            }

            if ($payment->status !== 'waiting_verification') {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran belum dalam status menunggu verifikasi.',
                ], 400);
            }

            $request->validate([
                'action' => 'required|in:approve,reject',
                'note'   => 'nullable|string|max:500',
            ]);

            if ($request->action === 'approve') {
                $payment->update([
                    'status'     => 'paid',
                    'paid_at'    => now(),
                    'admin_note' => $request->note,
                ]);

                ActivityLogger::log(
                    auth()->id(),
                    'Admin verifikasi bukti pelanggan',
                    'Admin setujui bukti transfer pelanggan untuk PAY-' . $payment->id,
                    'check_circle',
                    'Admin'
                );

                return response()->json([
                    'success' => true,
                    'message' => 'Bukti pembayaran diverifikasi. Siap transfer ke mitra.',
                    'data'    => $payment->fresh(),
                ], 200);
            } else {
                $payment->update([
                    'status'     => 'pending',
                    'admin_note' => 'DITOLAK: ' . ($request->note ?? '-'),
                ]);

                ActivityLogger::log(
                    auth()->id(),
                    'Admin tolak bukti pelanggan',
                    'Admin tolak bukti transfer pelanggan untuk PAY-' . $payment->id,
                    'cancel',
                    'Admin'
                );

                return response()->json([
                    'success' => true,
                    'message' => 'Bukti pembayaran ditolak. Pelanggan perlu upload ulang.',
                    'data'    => $payment->fresh(),
                ], 200);
            }

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('PaymentController@verifyCustomerProof: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memverifikasi: ' . $e->getMessage(),
            ], 500);
        }
    }

    // =============================================================
    // ADMIN — Transfer ke Mitra + Upload Bukti
    // POST /api/admin/payments/{id}/settle
    // =============================================================
    public function settle(Request $request, $id)
    {
        try {
            $payment = Payment::find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan.',
                ], 404);
            }

            if ($payment->status !== 'paid') {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran belum diverifikasi.',
                ], 400);
            }

            $request->validate([
                'mitra_proof' => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
                'note'        => 'nullable|string|max:500',
            ]);

            $path = $request->file('mitra_proof')->store('payment_proofs/mitra', 'public');

            $payment->update([
                'mitra_proof_url'         => '/storage/' . $path,
                'mitra_proof_uploaded_at' => now(),
                'status'                  => 'settled',
                'settled_at'              => now(),
                'admin_note'              => $request->note,
            ]);

            // Update job status jadi benar-benar selesai
            $job = jobs::find($payment->job_id);
            if ($job) {
                $job->update(['status' => 'Selesai']);
            }

            // Tambah poin mitra SEKARANG (setelah settled)
            $settings = system_setting::first();
            $pointsToAdd = $settings ? (int) $settings->points_on_completion : 10;

            $mitraProfile = mitra_profiles::where('user_id', $payment->mitra_id)->first();
            if ($mitraProfile) {
                $mitraProfile->increment('point', $pointsToAdd);
                $mitraProfile->increment('jobs_completed', 1);
            }

            ActivityLogger::log(
                auth()->id(),
                'Admin transfer ke mitra',
                'Admin upload bukti transfer ke mitra untuk PAY-' . $payment->id,
                'upload_file',
                'Admin'
            );

            return response()->json([
                'success' => true,
                'message' => 'Dana berhasil dicairkan ke mitra.',
                'data'    => $payment->fresh(),
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('PaymentController@settle: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mencairkan dana: ' . $e->getMessage(),
            ], 500);
        }
    }

    // =============================================================
    // ADMIN — Refund
    // PUT /api/admin/payments/{id}/refund
    // =============================================================
    public function refund(Request $request, $id)
    {
        try {
            $payment = Payment::find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan.',
                ], 404);
            }

            if (in_array($payment->status, ['settled', 'refunded'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran sudah settled atau sudah direfund.',
                ], 400);
            }

            $request->validate([
                'reason' => 'nullable|string|max:500',
            ]);

            $payment->update([
                'status'         => 'refunded',
                'payment_method' => 'refund',
                'admin_note'     => $request->reason,
            ]);

            ActivityLogger::log(
                auth()->id(),
                'Refund pembayaran',
                'Refund payment #' . $payment->id . ': ' . ($request->reason ?? '-'),
                'undo',
                'Admin'
            );

            return response()->json([
                'success' => true,
                'message' => 'Pembayaran berhasil direfund.',
                'data'    => $payment->fresh(),
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@refund: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal melakukan refund.',
            ], 500);
        }
    }
        /**
     * =============================================================
     * SUPER ADMIN — Overview Platform
     * GET /api/superadmin/payments/overview
     * =============================================================
     */
    public function superOverview()
    {
        try {
            $totalPembayaran   = (float) Payment::sum('total_paid');
            $totalKomisi       = (float) Payment::sum('commission_amount');
            $totalMitraEarning = (float) Payment::sum('mitra_earning');
            $totalTransaksi    = Payment::count();

            // Breakdown per status
            $perStatus = Payment::select(
                    'status',
                    DB::raw('COUNT(*) as total')
                )
                ->groupBy('status')
                ->pluck('total', 'status')
                ->toArray();

            // Pending amount (yang belum settled)
            $pendingAmount = (float) Payment::whereIn(
                    'status',
                    ['pending', 'waiting_verification', 'paid']
                )
                ->sum('mitra_earning');

            // Settled amount
            $settledAmount = (float) Payment::where('status', 'settled')
                ->sum('mitra_earning');

            return response()->json([
                'success' => true,
                'data' => [
                    'total_pembayaran'    => $totalPembayaran,
                    'total_komisi'        => $totalKomisi,
                    'total_mitra_earning' => $totalMitraEarning,
                    'total_transaksi'     => $totalTransaksi,
                    'pending_amount'      => $pendingAmount,
                    'settled_amount'      => $settledAmount,
                    'per_status'          => $perStatus,
                ],
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@superOverview: ' . $e->getMessage());
            Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat overview: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * =============================================================
     * SUPER ADMIN — Grafik Bulanan (12 bulan terakhir)
     * GET /api/superadmin/payments/chart
     * =============================================================
     */
    public function superChart()
    {
        try {
            // Group by YEAR + MONTH (kompatibel semua MySQL)
            $data = Payment::select(
                    DB::raw("YEAR(created_at) as tahun"),
                    DB::raw("MONTH(created_at) as bulan_angka"),
                    DB::raw('COUNT(*) as jumlah_transaksi'),
                    DB::raw('SUM(total_paid) as total_pembayaran'),
                    DB::raw('SUM(commission_amount) as total_komisi'),
                    DB::raw('SUM(mitra_earning) as total_mitra_earning')
                )
                ->where('created_at', '>=', now()->subMonths(11)->startOfMonth())
                ->groupBy('tahun', 'bulan_angka')
                ->orderBy('tahun', 'asc')
                ->orderBy('bulan_angka', 'asc')
                ->get();

            // Nama bulan Indonesia
            $namaBulan = [
                1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr',
                5 => 'Mei', 6 => 'Jun', 7 => 'Jul', 8 => 'Agu',
                9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des',
            ];

            $formatted = $data->map(function ($row) use ($namaBulan) {
                return [
                    'bulan'               => sprintf('%04d-%02d', $row->tahun, $row->bulan_angka),
                    'bulan_label'         => $namaBulan[(int) $row->bulan_angka] ?? '?',
                    'jumlah_transaksi'    => (int) $row->jumlah_transaksi,
                    'total_pembayaran'    => (float) $row->total_pembayaran,
                    'total_komisi'        => (float) $row->total_komisi,
                    'total_mitra_earning' => (float) $row->total_mitra_earning,
                ];
            });

            return response()->json([
                'success' => true,
                'data'    => $formatted,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@superChart: ' . $e->getMessage());
            Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat chart: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * =============================================================
     * SUPER ADMIN — Top Mitra by Earning
     * GET /api/superadmin/payments/top-mitra?limit=5
     * =============================================================
     */
    public function superTopMitra(Request $request)
    {
        try {
            $limit = (int) $request->query('limit', 10);
            if ($limit < 1) $limit = 10;
            if ($limit > 50) $limit = 50;

            // 1. Query agregat (tanpa with)
            $top = Payment::select(
                    'mitra_id',
                    DB::raw('COUNT(*) as total_transaksi'),
                    DB::raw('SUM(mitra_earning) as total_pendapatan'),
                    DB::raw('SUM(commission_amount) as total_komisi')
                )
                ->whereNotNull('mitra_id')
                ->where('status', '!=', 'refunded')
                ->groupBy('mitra_id')
                ->orderBy('total_pendapatan', 'desc')
                ->limit($limit)
                ->get();

            // 2. Ambil data user mitra manual
            $mitraIds = $top->pluck('mitra_id')->filter()->toArray();

            $mitraUsers = users::whereIn('id', $mitraIds)
                ->select('id', 'name', 'email')
                ->get()
                ->keyBy('id');

            // 3. Gabungkan
            $result = $top->map(function ($row) use ($mitraUsers) {
                $mitra = $mitraUsers->get($row->mitra_id);

                return [
                    'mitra_id'         => $row->mitra_id,
                    'total_transaksi'  => (int) $row->total_transaksi,
                    'total_pendapatan' => (float) $row->total_pendapatan,
                    'total_komisi'     => (float) $row->total_komisi,
                    'mitra'            => $mitra ? [
                        'id'    => $mitra->id,
                        'name'  => $mitra->name,
                        'email' => $mitra->email,
                    ] : null,
                ];
            });

            return response()->json([
                'success' => true,
                'data'    => $result,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@superTopMitra: ' . $e->getMessage());
            Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat top mitra: ' . $e->getMessage(),
            ], 500);
        }
    }
}