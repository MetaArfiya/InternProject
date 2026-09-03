<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class system_setting extends Model
{
    protected $table = 'system_settings';

    protected $fillable = [
        'updated_by',
        'points_on_completion',
        'points_on_cancellation',
        'points_bonus_rating',
        'platform_commission_percent',
    ];

    protected $casts = [
        'points_on_completion' => 'integer',
        'points_on_cancellation' => 'integer',
        'points_bonus_rating' => 'integer',
        'platform_commission_percent' => 'decimal:2',
    ];
}