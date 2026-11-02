<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlatformWallet extends Model
{
    protected $fillable = [
        'balance',
    ];

    protected $casts = [
        'balance' => 'float',
    ];
}