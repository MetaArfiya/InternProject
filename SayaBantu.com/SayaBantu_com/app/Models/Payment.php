<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'job_id',
        'pelanggan_id',
        'mitra_id',
        'job_amount',
        'commission_percent',
        'commission_amount',
        'total_paid',
        'mitra_earning',
        'status',
        'payment_method',
        'reference_code',
        'customer_proof_url',
        'customer_proof_uploaded_at',
        'customer_bank_name',
        'customer_account_name',
        'mitra_proof_url',
        'mitra_proof_uploaded_at',
        'admin_note',
        'paid_at',
        'settled_at',
        // TAMBAHAN BARU:
        'held_at',
        'customer_accepted_at',
        'released_at',
    ];

    protected $casts = [
        'job_amount' => 'float',
        'commission_percent' => 'float',
        'commission_amount' => 'float',
        'total_paid' => 'float',
        'mitra_earning' => 'float',
        'customer_proof_uploaded_at' => 'datetime',
        'mitra_proof_uploaded_at' => 'datetime',
        'paid_at' => 'datetime',
        'settled_at' => 'datetime',
        // TAMBAHAN BARU:
        'held_at' => 'datetime',
        'customer_accepted_at' => 'datetime',
        'released_at' => 'datetime',
    ];

    public function job()
    {
        return $this->belongsTo(jobs::class, 'job_id');
    }

    public function pelanggan()
    {
        return $this->belongsTo(users::class, 'pelanggan_id');
    }

    public function mitra()
    {
        return $this->belongsTo(users::class, 'mitra_id', 'id');
    }

    // OPSIONAL — relasi ke ledger
    public function walletTransactions()
    {
        return $this->hasMany(WalletTransaction::class, 'reference_id')
            ->where('reference_type', 'Payment');
    }
}