<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use App\Models\Topup;
use App\Providers\WalletService;
use App\Helpers\ActivityLogger;

class TopupController extends Controller
{
    protected WalletService $wallet;

    public function __construct(WalletService $wallet)
    {
        $this->wallet = $wallet;
    }

    // PELANGGAN / MITRA — Ajukan topup
    // POST /api/pelanggan/topups  (atau /api/mitra/topups)
    public function store(Request $request)
    {
        try {
            $request->validate([
                'amount'       => 'required|numeric|min:1000',
                'proof'        => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
                'bank_name'    => 'required|string|max:100',
                'account_name' => 'required|string|max:100',
            ]);

            $path = $request->file('proof')->store('topup_proofs', 'public');

            $topup = Topup::create([
                'user_id'      => auth()->id(),
                'amount'       => $request->amount,
                'proof_url'    => '/storage/' . $path,
                'bank_name'    => $request->bank_name,
                'account_name' => $request->account_name,
                'status'       => 'waiting_verification',
            ]);

            ActivityLogger::log(
                auth()->id(),
                'Ajukan topup saldo',
                'Topup #' . $topup->id . ' sebesar ' . $topup->amount,
                'upload_file',
                'User'
            );

            return response()->json([
                'success' => true,
                'message' => 'Pengajuan topup dikirim. Menunggu verifikasi admin.',
                'data'    => $topup,
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('TopupController@store: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengajukan topup: ' . $e->getMessage(),
            ], 500);
        }
    }

    // USER — Riwayat topup sendiri
    // GET /api/pelanggan/topups
    public function index()
    {
        try {
            $topups = Topup::where('user_id', auth()->id())
                ->latest()
                ->get();

            return response()->json([
                'success' => true,
                'data'    => $topups,
            ], 200);

        } catch (\Exception $e) {
            Log::error('TopupController@index: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat riwayat topup.',
            ], 500);
        }
    }

    // ADMIN — List semua topup
    // GET /api/admin/topups
    // ADMIN — List topup sesuai wilayah
    // GET /api/admin/topups
    public function adminIndex(Request $request)
    {
        try {
            $admin = auth()->user();

            $query = Topup::with('user:id,name,email,phone,city_id')
                ->latest();

            // ADMIN DAERAH
            // Hanya melihat topup dari user yang berada di kota admin tersebut
            if ($admin->role_id == 2 && $admin->city_id) {
                $query->whereHas('user', function ($q) use ($admin) {
                    $q->where('city_id', $admin->city_id);
                });
            }

            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }

            $topups = $query->get();

            return response()->json([
                'success' => true,
                'data'    => $topups,
            ], 200);

        } catch (\Exception $e) {
            Log::error('TopupController@adminIndex: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data topup.',
            ], 500);
        }
    }

    // ADMIN — Verifikasi topup
    // PUT /api/admin/topups/{id}/verify
    // ADMIN — Verifikasi topup
// PUT /api/admin/topups/{id}/verify
    public function verify(Request $request, $id)
    {
        try {
            $admin = auth()->user();

            $topup = Topup::with('user:id,name,email,phone,city_id')
                ->find($id);

            if (!$topup) {
                return response()->json([
                    'success' => false,
                    'message' => 'Topup tidak ditemukan.',
                ], 404);
            }

            // ============================================================
            // VALIDASI WILAYAH ADMIN DAERAH
            // ============================================================
            if ($admin->role_id == 2 && $admin->city_id) {

                if (!$topup->user || $topup->user->city_id != $admin->city_id) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Akses ditolak. User ini bukan dari wilayah Anda.',
                    ], 403);
                }
            }

            // ============================================================
            // VALIDASI STATUS
            // ============================================================
            if ($topup->status !== 'waiting_verification') {
                return response()->json([
                    'success' => false,
                    'message' => 'Topup tidak dalam status menunggu verifikasi.',
                ], 400);
            }

            // ============================================================
            // VALIDASI REQUEST
            // ============================================================
            $request->validate([
                'action' => 'required|in:approve,reject',
                'note'   => 'nullable|string|max:500',
            ]);

            // ============================================================
            // APPROVE
            // ============================================================
            if ($request->action === 'approve') {

                DB::transaction(function () use ($topup, $request, $admin) {

                    $this->wallet->credit(
                        $topup->user_id,
                        (float) $topup->amount,
                        'topup',
                        'Topup',
                        $topup->id,
                        'Topup disetujui admin'
                    );

                    $topup->update([
                        'status'      => 'approved',
                        'admin_note'  => $request->note,
                        'verified_at' => now(),
                        'verified_by' => $admin->id,
                    ]);
                });

                ActivityLogger::log(
                    $admin->id,
                    'Approve topup',
                    'Topup #' . $topup->id . ' disetujui',
                    'check_circle',
                    'Admin'
                );

                return response()->json([
                    'success' => true,
                    'message' => 'Topup disetujui. Saldo user bertambah.',
                    'data'    => $topup->fresh('user'),
                ], 200);
            }

            // ============================================================
            // REJECT
            // ============================================================
            $topup->update([
                'status'      => 'rejected',
                'admin_note'  => $request->note,
                'verified_at' => now(),
                'verified_by' => $admin->id,
            ]);

            ActivityLogger::log(
                $admin->id,
                'Reject topup',
                'Topup #' . $topup->id . ' ditolak',
                'cancel',
                'Admin'
            );

            return response()->json([
                'success' => true,
                'message' => 'Topup ditolak.',
                'data'    => $topup->fresh('user'),
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;

        } catch (\Exception $e) {
            Log::error('TopupController@verify: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memverifikasi topup: ' . $e->getMessage(),
            ], 500);
        }
    }

        // USER — Ambil info rekening bank platform
    // GET /api/platform-bank-account
    public function getPlatformBankAccount()
    {
        try {
            // MENGAMBIL DARI TABEL USERS
            // Asumsi: Rekening platform disimpan di user dengan role_id = 1 (Superadmin)
            // Sesuaikan 'role_id', 1 dengan ID role admin kamu.
            $platformAccount = \App\Models\users::where('role_id', 1)->first(); 

            if (!$platformAccount) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data rekening platform belum diatur.',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    // Pastikan nama kolom 'bank_name' dan 'account_number' 
                    // ini benar-benar ada di tabel users database kamu.
                    // Jika belum ada, kamu harus menambahkannya via migration.
                    'bank_name'      => $platformAccount->bank_name ?? 'BCA',
                    'account_number' => $platformAccount->account_number ?? '1234567890',
                    'account_name'   => $platformAccount->name ?? 'PT Sayabantu Indonesia',
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('TopupController@getPlatformBankAccount: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat info rekening.',
            ], 500);
        }
    }

}