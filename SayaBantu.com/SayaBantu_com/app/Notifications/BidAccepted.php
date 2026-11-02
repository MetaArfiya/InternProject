<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class BidAccepted extends Notification
{
    use Queueable;

    protected $job;

    public function __construct($job)
    {
        $this->job = $job;
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Penawaran Diterima',
            'type' => 'bid_accepted',
            'job_id' => $this->job->id,
            'job_title' => $this->job->tittle, // Perbaiki ejaan
            'message' => 'Selamat! Penawaran Anda untuk pekerjaan "' . $this->job->tittle . '" telah diterima!',
            'action_url' => '/jobs/' . $this->job->id,
        ];
    }
}