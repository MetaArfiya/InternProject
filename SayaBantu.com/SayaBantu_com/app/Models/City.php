<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class City extends Model
{
    use HasFactory;

    /**
     * Kolom yang boleh diisi (Mass Assignment)
     */
    protected $fillable = [
        'name',
    ];

    /**
     * Relasi ke User (Admin/Mitra)
     */
    public function users()
    {
        return $this->hasMany(users::class, 'city_id');
    }
}