<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class mitra_profiles extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',

        // Data profil
        'gender',
        'birth_date',
        'city',
        'bio',
        'skills',

        // Verifikasi
        'skill_photos',
        'verification_image',
        'selfie_image', 
        'certificate',
        'verified_by',
        'verified_at',

        // Statistik
        'point',
        'rating',
        'is_verified',

        // Pekerjaan
        'jobs_completed',
    ];

    protected $casts = [
        'certificate' => 'array',
        'skill_photos' => 'array',
        'rating' => 'float',
        'point' => 'integer',
        'is_verified' => 'boolean',
        'birth_date' => 'date:Y-m-d',
    ];

    // Relasi: Profil ini milik seorang User (Mitra)
    public function user()
    {
        return $this->belongsTo(users::class, 'user_id');
    }

    // Relasi: Profil ini diverifikasi oleh seorang User (Admin)
    public function verifier()
    {
        return $this->belongsTo(users::class, 'verified_by');
    }
}