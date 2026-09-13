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
        'status',
        'admin_response',
        'handled_by',
        'handled_at',
    ];

    protected $casts = [
        'handled_at' => 'datetime',
        'created_at' => 'datetime',
    ];

    // Relasi: Pengadu
    public function user()
    {
        return $this->belongsTo(users::class, 'user_id');
    }

    // Relasi: Job yang diadukan
    public function job()
    {
        return $this->belongsTo(jobs::class, 'job_id');
    }

    // Relasi: Admin yang menangani
    public function handler()
    {
        return $this->belongsTo(users::class, 'handled_by');
    }
}