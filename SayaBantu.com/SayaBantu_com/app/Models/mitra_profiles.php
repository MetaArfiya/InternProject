<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class mitra_profiles extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 
        'bio',
        'skills', 
        'verification_image', 
        'certificate',
        'point',
        'rating',
        'is_verified', 
        'verified_by', 
        'verified_at'
    ];

    protected $casts = [
        'certificate' => 'array',
        'rating' => 'float', // Kita cast ke float agar saat ditarik API berupa angka desimal (contoh: 4.7)
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