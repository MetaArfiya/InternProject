<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class JobCancellationRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'job_id',
        'requested_by',
        'approved_by',
        'reason',
        'status',
        'approved_at',
    ];

    protected $casts = [
        'approved_at' => 'datetime',
    ];

    public function job()
    {
        return $this->belongsTo(jobs::class, 'job_id');
    }

    public function requester()
    {
        return $this->belongsTo(users::class, 'requested_by');
    }

    public function approver()
    {
        return $this->belongsTo(users::class, 'approved_by');
    }
}