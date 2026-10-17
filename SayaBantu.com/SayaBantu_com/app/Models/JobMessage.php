<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class JobMessage extends Model
{
    protected $table = 'job_messages';

    protected $fillable = ['job_id', 'sender_id', 'message', 'read_at'];

    protected $casts = [
        'read_at' => 'datetime',
    ];

    public function sender()
    {
        return $this->belongsTo(users::class, 'sender_id');
    }

    public function job()
    {
        return $this->belongsTo(jobs::class, 'job_id');
    }
}