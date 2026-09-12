<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    /**
     * =========================================================
     * NAMA TABEL
     * =========================================================
     * Secara default Eloquent menganggap nama tabel = "payments"
     * (plural dari "Payment"). Jadi tidak perlu di-set ulang,
     * tapi ditulis eksplisit agar jelas.
     */
    protected $table = 'payments';

    /**
     * =========================================================
     * MASS ASSIGNMENT
     * =========================================================
     */
    protected $fillable = [
        'job_id',
        'pelanggan_id',
        'mitra_id',

        // Nominal
        'job_amount',
        'commission_percent',
        'commission_amount',
        'total_paid',
        'mitra_earning',

        // Status & metode
        'status',
        'payment_method',
        'reference_code',

        // Timestamp
        'paid_at',
        'settled_at',
    ];

    /**
     * =========================================================
     * CASTING
     * =========================================================
     * Decimal di-cast ke float agar mudah dihitung di Flutter.
     * Timestamp di-cast ke Carbon agar format otomatis.
     */
    protected $casts = [
        'job_amount'          => 'float',
        'commission_percent'  => 'float',
        'commission_amount'   => 'float',
        'total_paid'          => 'float',
        'mitra_earning'       => 'float',

        'paid_at'             => 'datetime',
        'settled_at'          => 'datetime',
    ];

    /**
     * =========================================================
     * RELASI
     * =========================================================
     */

    /**
     * Relasi: Payment ini milik sebuah Job.
     */
    public function job()
    {
        return $this->belongsTo(jobs::class, 'job_id');
    }

    /**
     * Relasi: Payment ini milik seorang Pelanggan.
     */
    public function pelanggan()
    {
        return $this->belongsTo(users::class, 'pelanggan_id');
    }

    /**
     * Relasi: Payment ini diterima oleh seorang Mitra.
     */
    public function mitra()
    {
        return $this->belongsTo(users::class, 'mitra_id');
    }

    /**
     * =========================================================
     * ACCESSOR TAMBAHAN (opsional)
     * =========================================================
     */

    /**
     * Status label untuk ditampilkan di UI.
     * Contoh: 'paid' → 'Berhasil'
     */
    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'pending'  => 'Menunggu',
            'paid'     => 'Berhasil',
            'settled'  => 'Selesai',
            'failed'   => 'Gagal',
            'refunded' => 'Dikembalikan',
            default    => 'Tidak Diketahui',
        };
    }

    /**
     * Format Rupiah dari total_paid.
     * Contoh: 166750 → "Rp 166.750"
     */
    public function getTotalPaidFormattedAttribute(): string
    {
        return 'Rp ' . number_format($this->total_paid, 0, ',', '.');
    }
}