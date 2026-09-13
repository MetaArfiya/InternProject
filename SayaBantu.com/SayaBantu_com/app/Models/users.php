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
        'bank_name',
        'bank_account_number',
        'bank_account_name',
        'is_active',
        'last_login_at',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_notification_enabled' => 'boolean',
        'is_active' => 'boolean',
        'last_login_at' => 'datetime',
    ];

    // ==================== RELASI ====================
    public function role()
    {
        return $this->belongsTo(\App\Models\roles::class, 'role_id', 'id');
    }

    public function mitraProfile()
    {
        return $this->hasOne(mitra_profiles::class, 'user_id', 'id');
    }

    public function jobsAsPelanggan()
    {
        return $this->hasMany(jobs::class, 'pelanggan_id');
    }

    public function jobsAsMitra()
    {
        return $this->hasMany(jobs::class, 'mitra_id');
    }

    public function bids()
    {
        return $this->hasMany(job_bids::class, 'mitra_id');
    }

    public function activityLogs()
    {
        return $this->hasMany(ActivityLog::class, 'user_id', 'id');
    }

    // ==================== ACCESSOR ====================
    public function getRoleNameAttribute(): string
    {
        if ($this->relationLoaded('role') && $this->role) {
            return $this->role->role_name ?? $this->role->name ?? 'Pelanggan';
        }

        if (!empty($this->attributes['role_name'] ?? null)) {
            return $this->attributes['role_name'];
        }

        if (isset($this->attributes['role']) && is_string($this->attributes['role'])) {
            return $this->attributes['role'];
        }

        try {
            $role = $this->role()->first();
            if ($role) {
                return $role->role_name ?? $role->name ?? 'Pelanggan';
            }
        } catch (\Exception $e) {
            // silent
        }

        return 'Pelanggan';
    }

    public function getBankAccountInfoAttribute(): string
    {
        if (empty($this->bank_name) || empty($this->bank_account_number)) {
            return '-';
        }

        return $this->bank_name
            . ' - ' . $this->bank_account_number
            . ' (' . ($this->bank_account_name ?? $this->name) . ')';
    }
}