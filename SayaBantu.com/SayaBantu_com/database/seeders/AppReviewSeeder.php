<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\AppReview;
use App\Models\users;

class AppReviewSeeder extends Seeder
{
    public function run(): void
    {
        // Ambil ID user berdasarkan nama persis yang ada di UserSeeder kamu
        $budi = users::where('name', 'Budi Santoso')->first();
        $spammer = users::where('name', 'Spammer123')->first();
        $sari = users::where('name', 'Sari Dewi')->first();

        // Ulasan 1: Menggunakan user Budi Santoso
        if ($budi) {
            AppReview::create([
                'user_id' => $budi->id,
                'headline_job' => 'Service AC Bocor',
                'profession' => 'Ibu Rumah Tangga, Cilandak',
                'comment' => 'Baru posting 10 menit, sudah ada 4 mitra yang nawar! Saya pilih yang poinnya paling tinggi, kerjanya beneran rapi dan profesional. Harganya juga bisa nego, jadi cocok banget sama budget saya.',
                'stars' => 5,
            ]);
        }

        // Ulasan 2: Menggunakan user Spammer123
        if ($spammer) {
            AppReview::create([
                'user_id' => $spammer->id,
                'headline_job' => 'Cat Ulang 8 Kamar Kos',
                'profession' => 'Pemilik Kos-kosan, Mampang',
                'comment' => 'Sebagai pemilik kos, saya sering butuh tukang mendadak. Dulu susah nyarinya, sekarang tinggal posting di SiapBantu dan tunggu tawaran masuk. Sudah 15+ pekerjaan lewat sini, semua beres.',
                'stars' => 5,
            ]);
        }

        // Ulasan 3: Menggunakan user Sari Dewi
        if ($sari) {
            AppReview::create([
                'user_id' => $sari->id,
                'headline_job' => 'Instalasi Wallpaper & Lampu',
                'profession' => 'Desainer Interior, Jakarta Selatan',
                'comment' => 'Yang saya suka adalah transparansinya — saya bisa lihat semua penawaran sekaligus, bandingkan poin mitra, dan pilih yang paling sesuai. Tidak ada biaya booking sama sekali, sungguh membantu.',
                'stars' => 5,
            ]);
        }
    }
}