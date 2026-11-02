<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Topup extends Model
{
    protected $fillable = [
        'user_id',
        'amount',
        'proof_url',
        'bank_name',
        'account_name',
        'status',
        'admin_note',
        'verified_at',
        'verified_by',
    ];

    protected $casts = [
        'amount'      => 'decimal:2',
        'verified_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(users::class);
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(users::class, 'verified_by');
    }
}