<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class job_bids extends Model
{
    use HasFactory;

    protected $table = 'job_bids';

    protected $fillable = ['job_id', 'mitra_id', 'offered_price', 'mitras_point_at_time', 'status'];

    // Relasi: Bid ini merujuk ke Job tertentu
    //relasi antara job_bids dan jobs adalah many to one, karena banyak bid bisa diajukan untuk satu job
    public function job()
    {
        return $this->belongsTo(jobs::class, 'job_id');
    }

    // Relasi: Bid ini diajukan oleh seorang Mitra
    public function mitra()
    {
        return $this->belongsTo(users::class, 'mitra_id');
    }

    public function user()
    {
        return $this->belongsTo(users::class, 'mitra_id');
    }

    public function mitraProfile()
    {
        return $this->belongsTo(mitra_profiles::class, 'mitra_id', 'user_id');
    }
}