<?php

namespace App\Notifications;

use App\Models\WarningLetter;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class WarningLetterIssued extends Notification
{
    use Queueable;

    public function __construct(private WarningLetter $warning) {}

    public function via($notifiable): array
    {
        return ['database'];
    }

    public function toDatabase($notifiable): array
    {
        return [
            'type' => 'warning_letter',
            'title' => 'Surat Peringatan (SP ' . $this->warning->level . ')',
            'message' => $this->warning->subject . ': ' . $this->warning->reason,
            'warning_letter_id' => $this->warning->id,
        ];
    }
}
