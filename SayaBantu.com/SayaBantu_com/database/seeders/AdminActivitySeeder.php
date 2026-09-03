<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\AdminActivity;

class AdminActivitySeeder extends Seeder
{
    public function run(): void
    {
        // Masukkan beberapa contoh data dummy aktivitas admin
        AdminActivity::insert([
            [
                'admin_id' => 1,
                'title' => 'Mitra Dewi Lestari berhasil diverifikasi',
                'icon' => 'verified',
                'color_type' => 'green',
                'created_at' => now()->subHours(5),
                'updated_at' => now()->subHours(5),
            ],
            [
                'admin_id' => 1,
                'title' => 'Pendaftaran Rudi Hartono ditolak: KTP tidak jelas',
                'icon' => 'cancel',
                'color_type' => 'red',
                'created_at' => now()->subDay(),
                'updated_at' => now()->subDay(),
            ],
            [
                'admin_id' => 1,
                'title' => 'Mitra Budi Santoso berhasil diverifikasi',
                'icon' => 'verified',
                'color_type' => 'green',
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
        ]);
    }
}