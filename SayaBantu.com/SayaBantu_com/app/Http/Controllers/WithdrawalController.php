<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\Withdrawal;
use App\Providers\WalletService;
use App\Helpers\ActivityLogger;

class WithdrawalController extends Controller
{
    protected WalletService $wallet;

    public function __construct(WalletService $wallet)
    {
        $this->wallet = $wallet;
    }

    // USER — Ajukan withdraw
    public function store(Request $request)
    {
        try {
            $request->validate([
                'amount'         => 'required|numeric|min:10000',
                'bank_name'      => 'required|string|max:100',
                'account_number' => 'required|string|max:50',
                'account_name'   => 'required|string|max:100',
                'pin'            => 'required|digits:6',
            ]);

            $user = auth()->user();

            if (!$user->pin || !Hash::check($request->pin, $user->pin)) {
                return response()->json([
                    'success' => false,
                    'message' => 'PIN yang Anda masukkan salah.',
                ], 400);
            }

            $userId = auth()->id();
            $wallet = $this->wallet->getOrCreate($userId);

            if ($wallet->balance < $request->amount) {
                return response()->json([
                    'success' => false,
                    'message' => 'Saldo tidak mencukupi untuk withdraw.',
                    'saldo_tersedia' => (float) $wallet->balance,
                    'kebutuhan'      => (float) $request->amount,
                ], 400);
            }

            $withdrawal = DB::transaction(function () use ($request, $userId) {
                // 1. BUAT WITHDRAWAL DULU UNTUK MENDAPATKAN ID
                $withdrawal = Withdrawal::create([
                    'user_id'        => $userId,
                    'amount'         => $request->amount,
                    'bank_name'      => $request->bank_name,
                    'account_number' => $request->account_number,
                    'account_name'   => $request->account_name,
                    'status'         => 'pending',
                ]);

                // 2. TAHAN SALDO DENGAN REFERENCE_ID YANG BENAR
                $this->wallet->debit(
                    $userId,
                    (float) $request->amount,
                    'withdraw',
                    'Withdrawal',
                    $withdrawal->id, // <-- Masukkan ID Withdrawal di sini
                    'Pengajuan withdraw (saldo ditahan)'
                );

                return $withdrawal;
            });

            ActivityLogger::log(
                $userId,
                'Ajukan withdraw',
                'Withdraw #' . $withdrawal->id . ' sebesar ' . $withdrawal->amount,
                'payment',
                'User'
            );

            return response()->json([
                'success' => true,
                'message' => 'Pengajuan withdraw dikirim. Menunggu proses admin.',
                'data'    => $withdrawal,
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Exception $e) {
            Log::error('WithdrawalController@store: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengajukan withdraw: ' . $e->getMessage(),
            ], 500);
        }
    }

    // USER — Riwayat withdraw sendiri
    public function index()
    {
        try {
            $withdrawals = Withdrawal::where('user_id', auth()->id())
                ->latest()
                ->get();

            return response()->json([
                'success' => true,
                'data'    => $withdrawals,
            ], 200);

        } catch (\Exception $e) {
            Log::error('WithdrawalController@index: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat riwayat withdraw.',
            ], 500);
        }
    }

    // ADMIN — List semua withdraw
    public function adminIndex(Request $request)
    {
        try {
            $admin = auth()->user();

            $query = Withdrawal::with('user:id,name,email,phone,city_id,bank_name,bank_account_number,bank_account_name')
                ->latest();

            // Admin Daerah hanya melihat withdrawal dari user di kotanya
            if ($admin->role_id == 2 && $admin->city_id) {
                $query->whereHas('user', function ($q) use ($admin) {
                    $q->where('city_id', $admin->city_id);
                });
            }

            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }

            $withdrawals = $query->get();

            return response()->json([
                'success' => true,
                'data' => $withdrawals,
            ]);
        } catch (\Exception $e) {
            Log::error('Gagal mengambil data withdrawal admin: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data withdrawal.',
            ], 500);
        }
    }

    // ADMIN — Proses withdraw (transfer manual + upload bukti)
    public function process(Request $request, $id)
    {
        try {
            $admin = auth()->user();

            $withdrawal = Withdrawal::with('user:id,name,email,phone,city_id,bank_name,bank_account_number,bank_account_name')
                ->find($id);

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal tidak ditemukan.',
                ], 404);
            }

            if (!in_array($withdrawal->status, ['pending', 'approved'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal sudah tidak dapat diproses.',
                ], 400);
            }

            // Admin Daerah hanya boleh memproses withdrawal dari kotanya
            if ($admin->role_id == 2 && $admin->city_id) {
                if (!$withdrawal->user || $withdrawal->user->city_id != $admin->city_id) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Anda tidak memiliki akses untuk memproses withdrawal dari kota ini.',
                    ], 403);
                }
            }

            $request->validate([
                'transfer_proof' => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
                'note'           => 'nullable|string|max:500',
            ]);

            $path = $request->file('transfer_proof')
                ->store('withdraw_proofs', 'public');

            $withdrawal->update([
                'status'             => 'transferred',
                'transfer_proof_url' => '/storage/' . $path,
                'admin_note'         => $request->note,
                'processed_at'       => now(),
                'processed_by'      => $admin->id,
            ]);

            ActivityLogger::log(
                $admin->id,
                'withdrawal_processed',
                'Memproses withdrawal #' . $withdrawal->id .
                ' sebesar Rp ' . number_format($withdrawal->amount, 0, ',', '.')
            );

            return response()->json([
                'success' => true,
                'message' => 'Withdrawal berhasil diproses dan bukti transfer berhasil disimpan.',
                'data'    => $withdrawal->fresh('user'),
            ]);
        } catch (\Exception $e) {
            Log::error('Gagal memproses withdrawal: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memproses withdrawal.',
            ], 500);
        }
    }

    // ADMIN — Tolak withdraw (kembalikan saldo)
    public function reject(Request $request, $id)
    {
        try {
            $admin = auth()->user();

            $withdrawal = Withdrawal::with('user:id,name,email,phone,city_id')
                ->find($id);

            if (!$withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal tidak ditemukan.',
                ], 404);
            }

            if (!in_array($withdrawal->status, ['pending', 'approved'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal sudah tidak dapat ditolak.',
                ], 400);
            }

            // Admin Daerah hanya boleh menolak withdrawal dari kotanya
            if ($admin->role_id == 2 && $admin->city_id) {
                if (!$withdrawal->user || $withdrawal->user->city_id != $admin->city_id) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Anda tidak memiliki akses untuk menolak withdrawal dari kota ini.',
                    ], 403);
                }
            }

            $request->validate([
                'reason' => 'nullable|string|max:500',
            ]);

            DB::transaction(function () use ($withdrawal, $request, $admin) {

                $this->wallet->refundWithdraw(
                    $withdrawal->user_id,
                    (float) $withdrawal->amount,
                    $withdrawal->id
                );

                $withdrawal->update([
                    'status'       => 'rejected',
                    'admin_note'   => $request->reason,
                    'processed_at' => now(),
                    'processed_by' => $admin->id,
                ]);
            });

            ActivityLogger::log(
                $admin->id,
                'withdrawal_rejected',
                'Menolak withdrawal #' . $withdrawal->id .
                ' sebesar Rp ' . number_format($withdrawal->amount, 0, ',', '.')
            );

            return response()->json([
                'success' => true,
                'message' => 'Withdrawal ditolak dan saldo pengguna telah dikembalikan.',
            ]);
        } catch (\Exception $e) {
            Log::error('Gagal menolak withdrawal: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal menolak withdrawal.',
            ], 500);
        }
    }
}
