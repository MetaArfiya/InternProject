<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class mitra_profiles extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'gender',
        'birth_date',
        'city',
        'bank_name',
        'bank_account_number',
        'bank_account_name',
        'bio',
        'skills',
        'pending_skill_photos',
        'pending_skills',
        'pending_certificate',
        'skills_updated_at',
        'skill_admin_note',
        'skill_photos',
        'verification_image',
        'selfie_image',
        'certificate',
        'verified_by',
        'verified_at',
        'point',
        'rating',
        'is_verified',
        'jobs_completed',
    ];

    protected $casts = [
        'certificate' => 'array',
        'skill_photos' => 'array',
        'pending_skill_photos' => 'array',
        'rating' => 'float',
        'point' => 'integer',
        'is_verified' => 'boolean',
        'birth_date' => 'date:Y-m-d',
        
        'skills_updated_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(users::class, 'user_id');
    }

    public function verifier()
    {
        return $this->belongsTo(users::class, 'verified_by');
    }

    public function getBankAccountInfoAttribute(): string
    {
        if (empty($this->bank_name) || empty($this->bank_account_number)) {
            return '-';
        }

        return $this->bank_name
            . ' - ' . $this->bank_account_number
            . ' (' . ($this->bank_account_name ?? '-') . ')';
    }
}