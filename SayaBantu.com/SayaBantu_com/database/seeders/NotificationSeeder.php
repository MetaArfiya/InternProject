<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\users;
use App\Models\jobs;
use Illuminate\Support\Str;
use Carbon\Carbon;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        $user = users::where('name', 'like', '%Budi Santoso%')->first();
        $userId = $user ? $user->id : 12;

        $now = Carbon::now();

        // Mengambil dummy job untuk referensi ID relasi data
        $jobAc = jobs::where('tittle', 'like', '%AC Bocor%')->first();
        $jobAcId = $jobAc ? $jobAc->id : 1;

        // 1. Penawaran Baru (Sesuai NewBidReceived class style)
        DB::table('notifications')->insert([
            'id' => Str::uuid()->toString(),
            'type' => 'App\Notifications\NewBidReceived',
            'notifiable_type' => 'App\Models\users',
            'notifiable_id' => $userId,
            'data' => json_encode([
                'job_id' => $jobAcId,
                'job_tittle' => 'Service AC Bocor di Ruang Tamu',
                'bid_id' => 1,
                'offered_price' => 150000,
                // Kolom tambahan opsional/pesan yang langsung dibaca frontend sesuai screenshot
                'tittle' => 'Penawaran Baru', 
                'message' => 'Budi Teknik AC mengirim penawaran untuk pekerjaan Anda.'
            ]),
            'read_at' => null,
            'created_at' => $now->copy()->subMinutes(2),
            'updated_at' => $now->copy()->subMinutes(2),
        ]);

        // 2. Pekerjaan Diproses
        DB::table('notifications')->insert([
            'id' => Str::uuid()->toString(),
            'type' => 'App\Notifications\JobProcessedNotification', 
            'notifiable_type' => 'App\Models\users',
            'notifiable_id' => $userId,
            'data' => json_encode([
                'job_id' => 2,
                'tittle' => 'Pekerjaan Diproses',
                'message' => 'Andi Service mulai mengerjakan pekerjaan Anda.'
            ]),
            'read_at' => null,
            'created_at' => $now->copy()->subHours(1),
            'updated_at' => $now->copy()->subHours(1),
        ]);

        // 3. Pekerjaan Selesai
        DB::table('notifications')->insert([
            'id' => Str::uuid()->toString(),
            'type' => 'App\Notifications\JobCompletedNotification',
            'notifiable_type' => 'App\Models\users',
            'notifiable_id' => $userId,
            'data' => json_encode([
                'job_id' => $jobAcId,
                'tittle' => 'Pekerjaan Selesai',
                'message' => 'Service AC Bocor telah selesai.'
            ]),
            'read_at' => null,
            'created_at' => $now->copy()->subDay(),
            'updated_at' => $now->copy()->subDay(),
        ]);

        // 4. Selamat Datang
        DB::table('notifications')->insert([
            'id' => Str::uuid()->toString(),
            'type' => 'App\Notifications\WelcomeNotification',
            'notifiable_type' => 'App\Models\users',
            'notifiable_id' => $userId,
            'data' => json_encode([
                'tittle' => 'Selamat Datang',
                'message' => 'Terima kasih telah bergabung di SayaBantu.'
            ]),
            'read_at' => null,
            'created_at' => $now->copy()->subDays(3),
            'updated_at' => $now->copy()->subDays(3),
        ]);
    }
}