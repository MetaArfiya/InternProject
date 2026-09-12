<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use App\Models\Payment;
use App\Models\jobs;
use App\Models\users;

class PaymentController extends Controller
{
    /**
     * =========================================================
     * PELANGGAN — Riwayat Pembayaran
     * GET /api/pelanggan/payments
     * =========================================================
     */
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

    /**
     * =========================================================
     * MITRA — Pendapatan
     * GET /api/mitra/earnings
     * =========================================================
     */
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
                ->where('status', '!=', 'pending')
                ->sum('mitra_earning');

            $totalPending = (float) $payments
                ->where('status', 'pending')
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

    /**
     * =========================================================
     * ADMIN — Semua Pembayaran
     * GET /api/admin/payments
     * =========================================================
     */
    public function adminIndex()
    {
        try {
            $payments = Payment::with([
                    'job:id,tittle,final_price',
                    'pelanggan:id,name',
                    'mitra:id,name',
                ])
                ->latest()
                ->get();

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

    /**
     * =========================================================
     * PELANGGAN — Bayar (manual trigger)
     * POST /api/payments/{id}/pay
     * =========================================================
     */
    public function pay(Request $request, $id)
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
                    'message' => 'Pembayaran sudah diproses sebelumnya.',
                ], 400);
            }

            $request->validate([
                'payment_method' => 'nullable|string|max:50',
            ]);

            $payment->update([
                'status'         => 'paid',
                'paid_at'        => now(),
                'payment_method' => $request->payment_method ?? 'manual',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pembayaran berhasil.',
                'data'    => $payment->fresh(),
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@pay: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memproses pembayaran.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * PELANGGAN — Detail Pembayaran
     * GET /api/payments/{id}
     * =========================================================
     */
    public function show($id)
    {
        try {
            $payment = Payment::with([
                    'job',
                    'pelanggan:id,name,email',
                    'mitra:id,name,email',
                ])
                ->find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan.',
                ], 404);
            }

            $userId = auth()->id();
            $user = auth()->user();
            $role = $user->role ?? null;

            // Validasi akses: hanya pelanggan, mitra terkait, atau admin/superadmin
            $isPelanggan = $payment->pelanggan_id === $userId;
            $isMitra     = $payment->mitra_id === $userId;
            $isAdmin     = in_array($role, ['Admin', 'Super Admin']);

            if (!$isPelanggan && !$isMitra && !$isAdmin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak berhak mengakses pembayaran ini.',
                ], 403);
            }

            return response()->json([
                'success' => true,
                'data'    => $payment,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@show: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat detail pembayaran.',
            ], 500);
        }
    }
        /**
     * =========================================================
     * ADMIN — Tandai Sudah Dibayar
     * PUT /admin/payments/{id}/mark-paid
     * =========================================================
     */
    public function markPaid(Request $request, $id)
    {
        try {
            $payment = Payment::find($id);

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran tidak ditemukan.',
                ], 404);
            }

            if ($payment->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Status pembayaran bukan pending.',
                ], 400);
            }

            $request->validate([
                'payment_method' => 'nullable|string|max:50',
            ]);

            $payment->update([
                'status'         => 'paid',
                'paid_at'        => now(),
                'payment_method' => $request->payment_method ?? 'transfer',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pembayaran ditandai sudah dibayar.',
                'data'    => $payment->fresh(),
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@markPaid: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal menandai pembayaran.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * ADMIN — Cairkan Dana ke Mitra
     * PUT /admin/payments/{id}/settle
     * =========================================================
     */
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
                    'message' => 'Pembayaran belum dibayar oleh pelanggan.',
                ], 400);
            }

            $payment->update([
                'status'     => 'settled',
                'settled_at' => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Dana berhasil dicairkan ke mitra.',
                'data'    => $payment->fresh(),
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@settle: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mencairkan dana.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * ADMIN — Refund
     * PUT /admin/payments/{id}/refund
     * =========================================================
     */
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
            ]);

            // (Opsional) Catat alasan refund ke activity log
            \App\Helpers\ActivityLogger::log(
                auth()->id(),
                'Refund pembayaran',
                'Refund payment #' . $payment->id . ' dengan alasan: ' . ($request->reason ?? '-'),
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
     * =========================================================
     * SUPER ADMIN — Overview Platform
     * GET /superadmin/payments/overview
     * =========================================================
     */
    public function superOverview()
    {
        try {
            $totalPembayaran   = (float) Payment::sum('total_paid');
            $totalKomisi       = (float) Payment::sum('commission_amount');
            $totalMitraEarning = (float) Payment::sum('mitra_earning');
            $totalTransaksi    = Payment::count();

            // Breakdown per status
            $perStatus = Payment::select('status', DB::raw('COUNT(*) as total'))
                ->groupBy('status')
                ->get()
                ->pluck('total', 'status');

            // Pending amount yang belum cair
            $pendingAmount = (float) Payment::where('status', 'pending')
                ->sum('total_paid');

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
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat overview.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * SUPER ADMIN — Grafik Bulanan (12 bulan terakhir)
     * GET /superadmin/payments/chart
     * =========================================================
     */
    public function superChart()
    {
        try {
            $data = Payment::select(
                    DB::raw("DATE_FORMAT(created_at, '%Y-%m') as bulan"),
                    DB::raw('COUNT(*) as jumlah_transaksi'),
                    DB::raw('SUM(total_paid) as total_pembayaran'),
                    DB::raw('SUM(commission_amount) as total_komisi'),
                    DB::raw('SUM(mitra_earning) as total_mitra_earning')
                )
                ->where('created_at', '>=', now()->subMonths(11)->startOfMonth())
                ->groupBy('bulan')
                ->orderBy('bulan', 'asc')
                ->get();

            return response()->json([
                'success' => true,
                'data'    => $data,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@superChart: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat grafik.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * SUPER ADMIN — Top Mitra by Earning
     * GET /superadmin/payments/top-mitra
     * =========================================================
     */
    public function superTopMitra(Request $request)
    {
        try {
            $limit = (int) $request->query('limit', 10);

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
                ->with('mitra:id,name,email')
                ->get();

            return response()->json([
                'success' => true,
                'data'    => $top,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@superTopMitra: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat top mitra.',
            ], 500);
        }
    }
        /**
     * =========================================================
     * MITRA — Statistik Bulanan (untuk grafik & ringkasan)
     * GET /mitra/earnings/monthly
     * =========================================================
     */
    public function mitraMonthlyStats(Request $request)
    {
        try {
            $userId = auth()->id();

            // Berapa bulan terakhir (default 6)
            $months = (int) $request->query('months', 6);
            $startDate = now()->subMonths($months - 1)->startOfMonth();

            // -------------------------------------------------
            // Data per bulan (untuk grafik line chart)
            // -------------------------------------------------
            $monthly = Payment::select(
                    DB::raw("DATE_FORMAT(created_at, '%Y-%m') as bulan"),
                    DB::raw("DATE_FORMAT(created_at, '%b') as bulan_label"),
                    DB::raw("COUNT(*) as jumlah_pekerjaan"),
                    DB::raw("SUM(mitra_earning) as total_pendapatan")
                )
                ->where('mitra_id', $userId)
                ->where('status', '!=', 'refunded')
                ->where('created_at', '>=', $startDate)
                ->groupBy('bulan', 'bulan_label')
                ->orderBy('bulan', 'asc')
                ->get();

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
                    'total_pendapatan'     => $totalPendapatan,
                    'total_pekerjaan'      => $totalPekerjaan,
                    'rata_rata_per_bulan'  => round($rataRataPerBulan, 2),
                ],
                'monthly' => $monthly,
            ], 200);

        } catch (\Exception $e) {
            Log::error('PaymentController@mitraMonthlyStats: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat statistik bulanan.',
            ], 500);
        }
    }
}