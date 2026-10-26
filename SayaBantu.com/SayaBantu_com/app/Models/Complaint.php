<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Complaint extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'user_role',
        'category',
        'title',
        'description',
        'job_id',
        'proof_photo',
        'status',
        'admin_response',
        'handled_by',
        'handled_at',
    ];

    // Tidak perlu $appends kalau Flutter pakai proof_photo langsung
    // Tapi kalau mau konsisten dengan pola photo_url user:
    protected $appends = ['proof_photo_url'];

    protected $casts = [
        'handled_at' => 'datetime',
        'created_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(users::class, 'user_id');
    }

    public function job()
    {
        return $this->belongsTo(jobs::class, 'job_id');
    }

    public function handler()
    {
        return $this->belongsTo(users::class, 'handled_by');
    }

    /**
     * Sama seperti users.photo_url: kirim path relatif saja.
     * Flutter yang akan menggabungkan dengan baseUrl + /storage/
     */
    public function getProofPhotoUrlAttribute()
    {
        return $this->proof_photo;  // contoh: "complaints/xxx.png"
    }
}