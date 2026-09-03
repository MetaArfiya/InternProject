<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use App\Models\users;

class NewMitraRegistered extends Notification
{
    use Queueable;

    protected $mitra;

    public function __construct(User $mitra)
    {
        $this->mitra = $mitra;
    }

    public function via($notifiable)
    {
        return ['database']; // Menyimpan ke tabel notifications di database admin
    }

    public function toArray($notifiable)
    {
        return [
            'mitra_id' => $this->mitra->id,
            'mitra_name' => $this->mitra->name,
            'message' => "Mitra baru bernama '" . $this->mitra->name . "' telah mengunggah KTP. Segera lakukan verifikasi berkas!"
        ];
    }
}