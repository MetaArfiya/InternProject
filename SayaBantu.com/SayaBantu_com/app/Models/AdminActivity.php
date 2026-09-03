<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdminActivity extends Model
{
    use HasFactory;

    protected $table = 'admin_activities';

    protected $fillable = [
        'admin_id',
        'title',
        'icon',
        'color_type',
    ];

    public function admin()
    {
        return $this->belongsTo(users::class, 'admin_id');
    }
}