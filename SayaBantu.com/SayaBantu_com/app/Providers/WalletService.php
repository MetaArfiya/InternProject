<?php

namespace App\Providers;

use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Models\PlatformWallet; // Pastikan model ini sudah dibuat
use Illuminate\Support\Facades\DB;
use RuntimeException;

class WalletService
{
    public function getOrCreate(int $userId): Wallet
    {
        return Wallet::firstOrCreate(
            ['user_id' => $userId],
            ['balance' => 0, 'held_balance' => 0]
        );
    }

    /**
     * Tambah saldo (topup, earning, refund).
     */
    public function credit(
        int $userId,
        float $amount,
        string $type,
        ?string $refType = null,
        ?int $refId = null,
        ?string $desc = null
    ): Wallet {
        if ($amount <= 0) {
            throw new RuntimeException('Nominal credit harus lebih dari 0.');
        }

        return DB::transaction(function () use ($userId, $amount, $type, $refType, $refId, $desc) {
            $wallet = $this->getOrCreate($userId);
            $wallet->increment('balance', $amount);
            $wallet->refresh();

            $this->log($wallet, $type, $amount, $refType, $refId, $desc);

            return $wallet;
        });
    }

    /**
     * Kurangi saldo tersedia (withdraw hold, dll).
     */
    public function debit(
        int $userId,
        float $amount,
        string $type,
        ?string $refType = null,
        ?int $refId = null,
        ?string $desc = null
    ): Wallet {
        if ($amount <= 0) {
            throw new RuntimeException('Nominal debit harus lebih dari 0.');
        }

        return DB::transaction(function () use ($userId, $amount, $type, $refType, $refId, $desc) {
            $wallet = $this->getOrCreate($userId);

            if ($wallet->balance < $amount) {
                throw new RuntimeException('Saldo tidak mencukupi.');
            }

            $wallet->decrement('balance', $amount);
            $wallet->refresh();

            $this->log($wallet, $type, -$amount, $refType, $refId, $desc);

            return $wallet;
        });
    }

    /**
     * Tahan saldo pelanggan untuk pembayaran job (escrow).
     */
    public function hold(int $userId, float $amount, int $paymentId): void
    {
        if ($amount <= 0) {
            throw new RuntimeException('Nominal hold harus lebih dari 0.');
        }

        DB::transaction(function () use ($userId, $amount, $paymentId) {
            $wallet = $this->getOrCreate($userId);

            if ($wallet->balance < $amount) {
                throw new RuntimeException('Saldo tidak mencukupi untuk pembayaran job.');
            }

            $wallet->decrement('balance', $amount);
            $wallet->increment('held_balance', $amount);
            $wallet->refresh();

            $this->log(
                $wallet,
                'payment_hold',
                -$amount,
                'Payment',
                $paymentId,
                'Dana ditahan untuk pembayaran job'
            );
        });
    }

    /**
     * Mencairkan dana escrow secara otomatis:
     * - Mengurangi held_balance pelanggan sebesar total pembayaran.
     * - Menambahkan pendapatan bersih ke saldo mitra.
     * - Menambahkan komisi ke saldo platform.
     *
     * Pemanggilan harus dilakukan dalam transaksi pembayaran
     * yang sudah mengunci baris Payment.
     */
    public function releasePayment(
        int $pelangganId,
        int $mitraId,
        float $totalPaid,
        float $mitraEarning,
        float $commission,
        int $paymentId
    ): void {
        if ($totalPaid <= 0) {
            throw new RuntimeException(
                'Total pembayaran harus lebih dari 0.'
            );
        }

        if ($mitraEarning <= 0) {
            throw new RuntimeException(
                'Pendapatan mitra tidak valid.'
            );
        }

        if ($commission < 0) {
            throw new RuntimeException(
                'Komisi platform tidak valid.'
            );
        }

        // Pastikan pembagian dana tepat.
        if (round($mitraEarning + $commission, 2) !== round($totalPaid, 2)) {
            throw new RuntimeException(
                'Total pembayaran tidak sesuai dengan pembagian mitra dan komisi.'
            );
        }

        if ($pelangganId === $mitraId) {
            throw new RuntimeException(
                'Pelanggan dan mitra tidak boleh menggunakan akun yang sama.'
            );
        }

        DB::transaction(function () use (
            $pelangganId,
            $mitraId,
            $totalPaid,
            $mitraEarning,
            $commission,
            $paymentId
        ) {

            // ============================================
            // 1. KUNCI WALLET PELANGGAN
            // ============================================
            $pelanggan = Wallet::where('user_id', $pelangganId)
                ->lockForUpdate()
                ->first();

            if (!$pelanggan) {
                throw new RuntimeException(
                    'Wallet pelanggan tidak ditemukan.'
                );
            }

            if ((float) $pelanggan->held_balance < $totalPaid) {
                throw new RuntimeException(
                    'Saldo ditahan pelanggan tidak mencukupi.'
                );
            }

            // Lepaskan seluruh dana escrow pelanggan.
            $pelanggan->held_balance =
                (float) $pelanggan->held_balance - $totalPaid;

            $pelanggan->save();
            $pelanggan->refresh();

            $this->log(
                $pelanggan,
                'payment_release',
                0,
                'Payment',
                $paymentId,
                'Dana escrow sebesar Rp ' .
                    number_format($totalPaid, 0, ',', '.') .
                    ' dilepas setelah pelanggan ACC.'
            );

            // ============================================
            // 2. KREDIT SALDO MITRA
            // ============================================
            $mitra = Wallet::firstOrCreate(
                ['user_id' => $mitraId],
                ['balance' => 0, 'held_balance' => 0]
            );

            // Kunci wallet mitra sebelum mengubah saldo.
            $mitra = Wallet::where('user_id', $mitraId)
                ->lockForUpdate()
                ->first();

            if (!$mitra) {
                throw new RuntimeException(
                    'Wallet mitra gagal dibuat.'
                );
            }

            $mitra->balance =
                (float) $mitra->balance + $mitraEarning;

            $mitra->save();
            $mitra->refresh();

            $this->log(
                $mitra,
                'earning',
                $mitraEarning,
                'Payment',
                $paymentId,
                'Pendapatan bersih pekerjaan setelah pelanggan ACC.'
            );

            // ============================================
            // 3. KREDIT KOMISI PLATFORM
            // ============================================
            // $platform = PlatformWallet::firstOrCreate(
            //     ['id' => 1],
            //     ['balance' => 0]
            // );

            $platform = PlatformWallet::firstOrCreate(
                [],
                ['balance' => 0]
            );

            // Kunci wallet platform.
            $platform = PlatformWallet::where('id', $platform->id)
                ->lockForUpdate()
                ->first();

            if (!$platform) {
                throw new RuntimeException(
                    'Wallet platform tidak ditemukan.'
                );
            }

            $platform->balance =
                (float) $platform->balance + $commission;

            $platform->save();
        });
    }

    /**
     * Lepas escrow pelanggan → kredit saldo mitra (Fungsi Lama).
     * Biarkan saja jika masih dipakai di modul lain.
     */
    public function releaseHold(int $pelangganId, int $mitraId, float $amount, int $paymentId): void
    {
        if ($amount <= 0) {
            throw new RuntimeException('Nominal release harus lebih dari 0.');
        }

        DB::transaction(function () use ($pelangganId, $mitraId, $amount, $paymentId) {
            $pelanggan = $this->getOrCreate($pelangganId);

            if ($pelanggan->held_balance < $amount) {
                throw new RuntimeException('Saldo ditahan pelanggan tidak mencukupi.');
            }

            $pelanggan->decrement('held_balance', $amount);
            $pelanggan->refresh();

            $this->log($pelanggan, 'payment_release', 0, 'Payment', $paymentId, 'Dana escrow dilepas ke mitra');

            $mitra = $this->getOrCreate($mitraId);
            $mitra->increment('balance', $amount);
            $mitra->refresh();

            $this->log($mitra, 'earning', $amount, 'Payment', $paymentId, 'Pendapatan dari job');
        });
    }

    /**
     * Refund: kembalikan dari held_balance ke balance pelanggan.
     */
    public function refundHold(int $userId, float $amount, int $paymentId): void
    {
        if ($amount <= 0) {
            throw new RuntimeException('Nominal refund harus lebih dari 0.');
        }

        DB::transaction(function () use ($userId, $amount, $paymentId) {
            $wallet = $this->getOrCreate($userId);

            if ($wallet->held_balance < $amount) {
                throw new RuntimeException('Saldo ditahan tidak mencukupi untuk refund.');
            }

            $wallet->decrement('held_balance', $amount);
            $wallet->increment('balance', $amount);
            $wallet->refresh();

            $this->log(
                $wallet,
                'refund',
                $amount,
                'Payment',
                $paymentId,
                'Refund dari escrow ke saldo pelanggan'
            );
        });
    }

    /**
     * Kembalikan saldo saat withdraw ditolak.
     */
    public function refundWithdraw(int $userId, float $amount, int $withdrawalId): void
    {
        if ($amount <= 0) {
            throw new RuntimeException('Nominal refund withdraw harus lebih dari 0.');
        }

        DB::transaction(function () use ($userId, $amount, $withdrawalId) {
            $wallet = $this->getOrCreate($userId);
            $wallet->increment('balance', $amount);
            $wallet->refresh();

            $this->log(
                $wallet,
                'withdraw_refund',
                $amount,
                'Withdrawal',
                $withdrawalId,
                'Pengembalian saldo karena withdraw ditolak'
            );
        });
    }

    private function log(
        Wallet $wallet,
        string $type,
        float $amount,
        ?string $refType,
        ?int $refId,
        ?string $desc
    ): void {
        WalletTransaction::create([
            'user_id'        => $wallet->user_id,
            'type'           => $type,
            'amount'         => $amount,
            'balance_after'  => $wallet->balance,
            'reference_type' => $refType,
            'reference_id'   => $refId,
            'description'    => $desc,
        ]);
    }
}