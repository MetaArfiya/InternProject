<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rating extends Model
{
    use HasFactory;

    protected $fillable = [
        'job_id',
        'mitra_id',
        'pelanggan_id',
        'stars',
        'comment',
        'is_hidden',
        'hidden_by',
        'hidden_at',
        'hidden_reason',
    ];

    protected $casts = [
        'stars'       => 'integer',
        'is_hidden'   => 'boolean',
        'hidden_at'   => 'datetime',
        'created_at'  => 'datetime',
    ];

    public function job()
    {
        return $this->belongsTo(jobs::class, 'job_id');
    }

    public function mitra()
    {
        return $this->belongsTo(users::class, 'mitra_id');
    }

    public function pelanggan()
    {
        return $this->belongsTo(users::class, 'pelanggan_id');
    }

    public function hider()
    {
        return $this->belongsTo(users::class, 'hidden_by');
    }
}