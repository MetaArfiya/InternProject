<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\WalletTransaction;
use App\Models\Topup;
use App\Models\Withdrawal;
use App\Providers\WalletService;

class WalletController extends Controller
{
    protected WalletService $wallet;

    public function __construct(WalletService $wallet)
    {
        $this->wallet = $wallet;
    }

    public function show(Request $request)
    {
        try {
            $userId = auth()->id();
            $wallet = $this->wallet->getOrCreate($userId);

            $limit = (int) $request->query('limit', 50);
            if ($limit < 1) $limit = 50;
            if ($limit > 200) $limit = 200;

            $transactions = WalletTransaction::where('user_id', $userId)
                ->latest()
                ->limit($limit)
                ->get()
                ->map(function ($tx) {
                    $proofUrl = null;
                    
                    // 1. Cek Tipe (Ubah ke huruf kecil agar aman)
                    $refType = strtolower($tx->reference_type);
                    $refId = $tx->reference_id;

                    // LOG UNTUK DEBUG (Cek di storage/logs/laravel.log)
                    Log::info("TX Debug: ID {$tx->id}, Type: {$refType}, RefID: {$refId}");

                    // 2. Logika Topup
                    if ($refType === 'topup') {
                        $topup = Topup::find($refId);
                        if ($topup && $topup->proof_url) {
                            $filename = basename($topup->proof_url);
                            // Gunakan /api di depan karena route ada di api.php
                            $proofUrl = '/api/images/topup_proofs/' . $filename;
                        }
                    } 
                    // 3. Logika Withdrawal
                    elseif ($refType === 'withdrawal') {
                        $withdrawal = Withdrawal::find($refId);
                        
                        // LOG UNTUK DEBUG
                        if ($withdrawal) {
                            Log::info("Withdrawal Found: ID {$withdrawal->id}, Status: {$withdrawal->status}, Proof: {$withdrawal->transfer_proof_url}");
                        } else {
                            Log::warning("Withdrawal NOT Found for RefID: {$refId}");
                        }

                        if ($withdrawal && $withdrawal->transfer_proof_url) {
                            $filename = basename($withdrawal->transfer_proof_url);
                            $proofUrl = '/api/images/withdraw_proofs/' . $filename;
                        }
                    }

                    return [
                        'id' => $tx->id,
                        'type' => $tx->type,
                        'amount' => $tx->amount,
                        'description' => $tx->description,
                        'created_at' => $tx->created_at,
                        'proof_url' => $proofUrl, 
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => [
                    'saldo_tersedia' => (float) $wallet->balance,
                    'saldo_ditahan'  => (float) $wallet->held_balance,
                    'transactions'   => $transactions,
                ],
            ], 200);

        } catch (\Exception $e) {
            Log::error('WalletController@show: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat wallet: ' . $e->getMessage(),
            ], 500);
        }
    }
}