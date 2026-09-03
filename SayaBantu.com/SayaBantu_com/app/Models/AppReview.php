<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppReview extends Model
{
    use HasFactory;

    protected $table = 'app_reviews';

    protected $fillable = [
        'user_id',
        'headline_job',
        'profession',
        'comment',
        'stars'
    ];

    // Hubungkan ulasan dengan user agar bisa mengambil nama & photo_profile
    public function user()
    {
        return $this->belongsTo(users::class, 'user_id');
    }
}