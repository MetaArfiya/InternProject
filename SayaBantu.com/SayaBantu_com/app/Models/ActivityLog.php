<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ActivityLog extends Model
{
    use HasFactory;

    protected $table = 'activity_logs';

    protected $fillable = [
        'user_id',
        'title',
        'detail',
        'icon',
        'type',
    ];

    /**
     * User yang melakukan aktivitas
     */
    public function user()
    {
        return $this->belongsTo(
            users::class,
            'user_id'
        );
    }
}