<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BalanceRequest extends Model
{
    protected $fillable = [
        'user_id', 'type', 'amount', 'bank_name', 'account_number',
        'account_name', 'note', 'status', 'reviewed_by', 'admin_note',
    ];

    public function user() { return $this->belongsTo(users::class, 'user_id'); }
    public function reviewer() { return $this->belongsTo(users::class, 'reviewed_by'); }
}
