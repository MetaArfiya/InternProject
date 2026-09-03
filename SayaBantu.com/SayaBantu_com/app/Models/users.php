<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Models\ActivityLog;

class users extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role_id',
        'photo_profile',
        'is_notification_enabled',
        'phone',
        'address',
        'is_active',
        'last_login_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_notification_enabled' => 'boolean',
        'is_active' => 'boolean',
        'last_login_at' => 'datetime',
    ];

    public function role()
    {
        return $this->belongsTo(
            \App\Models\roles::class,
            'role_id',
            'id'
        );
    }

    public function mitraProfile()
    {
        return $this->hasOne(
            mitra_profiles::class,
            'user_id',
            'id'
        );
    }

    public function jobsAsPelanggan()
    {
        return $this->hasMany(
            jobs::class,
            'pelanggan_id'
        );
    }

    public function jobsAsMitra()
    {
        return $this->hasMany(
            jobs::class,
            'mitra_id'
        );
    }

    public function bids()
    {
        return $this->hasMany(
            job_bids::class,
            'mitra_id'
        );
    }

    public function activityLogs()
    {
        return $this->hasMany(
            ActivityLog::class,
            'user_id',
            'id'
        );
    }
}