<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use App\Models\jobs;
use App\Models\job_bids;

class PartnerAcceptedJob extends Notification
{
    use Queueable;

    public function __construct(
        private jobs $job,
        private job_bids $bid
    ) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Mitra Menerima Pekerjaan',
            'type' => 'job_assigned',
            'job_id' => $this->job->id,
            'job_title' => $this->job->tittle,
            'mitra_id' => $this->bid->mitra_id,
            'message' => 'Mitra menyetujui pekerjaan Anda dengan harga ' .
                'dan jadwal yang telah ditentukan.',
            'action_url' => '/jobs/' . $this->job->id,
        ];
    }
}
