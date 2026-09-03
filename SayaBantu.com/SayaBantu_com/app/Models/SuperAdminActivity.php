<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\users;

class SuperAdminActivity extends Model
{
    use HasFactory;

    protected $table = 'superadmin_activities';

    protected $fillable = [
        'super_admin_id',
        'title',
        'detail',
        'icon',
        'type',
    ];

    public function superAdmin()
    {
        return $this->belongsTo(
            users::class,
            'super_admin_id',
            'id'
        );
    }
}