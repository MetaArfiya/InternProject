<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WarningLetter extends Model
{
    protected $fillable = ['user_id', 'admin_id', 'recipient_role', 'level', 'subject', 'reason'];

    public function recipient() { return $this->belongsTo(users::class, 'user_id'); }
    public function issuer() { return $this->belongsTo(users::class, 'admin_id'); }
}
