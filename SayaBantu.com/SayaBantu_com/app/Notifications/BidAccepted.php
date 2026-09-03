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
            'job_id' => $this->job->id,
            'tittle' => $this->job->tittle,
            'message' => 'Penawaran Anda untuk pekerjaan "' . $this->job->title . '" telah diterima!',
            'action_url' => '/jobs/' . $this->job->id,
        ];
    }
}