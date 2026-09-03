<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class jobs extends Model
{
    use HasFactory;

    protected $fillable = [
        'pelanggan_id', 
        'mitra_id', 
        'tittle', 
        'description', 
        'category',
        'location',
        'image_url', 
        'initial_budget', 
        'final_price', 
        'status',
        'is_verified',
        'verified_by'
    ];

    // Relasi: Job ini diposting oleh Pelanggan
    public function pelanggan()
    {
        return $this->belongsTo(users::class, 'pelanggan_id');
    }

    // Relasi: Job ini diambil/dikerjakan oleh Mitra
    public function mitra()
    {
        return $this->belongsTo(users::class, 'mitra_id');
    }

    // Relasi: Job ini diverifikasi oleh Admin/User tertentu
    public function verifier()
    {
        return $this->belongsTo(users::class, 'verified_by');
    }

    // Relasi: Job ini memiliki banyak Bid/Antrean tawaran harga
    public function bids()
    {
        return $this->hasMany(job_bids::class, 'job_id');
    }
}