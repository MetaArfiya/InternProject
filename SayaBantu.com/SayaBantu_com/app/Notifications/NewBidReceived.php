<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use App\Models\jobs;
use App\Models\job_bids;

class NewBidReceived extends Notification
{
    use Queueable;

    protected $job;
    protected $bid;

    public function __construct(jobs $job, job_bids $bid)
    {
        $this->job = $job;
        $this->bid = $bid;
    }

    public function via($notifiable)
    {
        return ['database']; // Menyimpan notifikasi ke tabel notifications di database
    }

    public function toArray($notifiable)
    {
        return [
            'job_id' => $this->job->id,
            'job_tittle' => $this->job->tittle,
            'bid_id' => $this->bid->id,
            'offered_price' => $this->bid->offered_price,
            'message' => "Ada penawaran baru sebesar Rp " . number_format($this->bid->offered_price, 0, ',', '.') . " untuk pekerjaan '" . $this->job->tittle . "'."
        ];
    }
}