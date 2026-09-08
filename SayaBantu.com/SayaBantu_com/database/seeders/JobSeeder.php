<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\jobs;
use App\Models\users;

class JobSeeder extends Seeder
{
    public function run(): void
    {
        // Ambil user pelanggan
        $pelanggan = users::where('name', 'Budi Santoso')->first();
        $pelangganId = $pelanggan ? $pelanggan->id : 4;

        // =====================================================
        // JOB 1
        // =====================================================
        jobs::create([
            'pelanggan_id' => $pelangganId,
            'mitra_id' => null,
            'tittle' => 'Service AC Bocor di Ruang Tamu',
            'description' => 'AC 1 PK merek Sharp, bocor terus dari bagian atas. Sudah dibersihkan tetapi masih bocor.',
            'category' => 'Instalasi & Teknisi',
            'location' => 'Sidoarjo, Jawa Timur',
            'latitude' => -7.4478,
            'longitude' => 112.7183,
            'location_description' => 'Rumah warna putih dengan pagar hitam. Ruang tamu berada di bagian depan rumah.',
            'image_url' => null,
            'initial_budget' => 150000,
            'final_price' => null,
            'duration' => '1–2 Jam',
            'started_at' => null,
            'completed_at' => null,
            'status' => 'Mencari Mitra',
            'is_verified' => 0,
            'verified_by' => null,
        ]);

        // =====================================================
        // JOB 2
        // =====================================================
        jobs::create([
            'pelanggan_id' => $pelangganId,
            'mitra_id' => null,
            'tittle' => 'Pasang Kran Air Dapur Bocor',
            'description' => 'Kran dapur bocor parah, air terus menetes. Perlu penggantian kran baru.',
            'category' => 'Instalasi & Teknisi',
            'location' => 'Surabaya Barat',
            'latitude' => -7.2575,
            'longitude' => 112.7521,
            'location_description' => 'Rumah berada di dalam gang. Pagar rumah berwarna cokelat dan berada di dekat warung.',
            'image_url' => null,
            'initial_budget' => 95000,
            'final_price' => null,
            'duration' => '3–5 Jam',
            'started_at' => null,
            'completed_at' => null,
            'status' => 'Mencari Mitra',
            'is_verified' => 0,
            'verified_by' => null,
        ]);

        // =====================================================
        // JOB 3
        // =====================================================
        jobs::create([
            'pelanggan_id' => $pelangganId,
            'mitra_id' => null,
            'tittle' => 'Cat Ulang Kamar Tidur 3x4m',
            'description' => 'Kamar tidur perlu dicat ulang dengan warna putih bersih. Cat dan peralatan disediakan oleh pelanggan.',
            'category' => 'Perbaikan & Perawatan Rumah',
            'location' => 'Surabaya Timur',
            'latitude' => -7.2657,
            'longitude' => 112.7688,
            'location_description' => 'Rumah dua lantai dengan pagar putih. Kamar yang akan dicat berada di lantai dua.',
            'image_url' => null,
            'initial_budget' => 320000,
            'final_price' => null,
            'duration' => '1 Hari',
            'started_at' => null,
            'completed_at' => null,
            'status' => 'Mencari Mitra',
            'is_verified' => 0,
            'verified_by' => null,
        ]);

        // =====================================================
        // JOB 4
        // =====================================================
        jobs::create([
            'pelanggan_id' => $pelangganId,
            'mitra_id' => null,
            'tittle' => 'Perbaikan Pintu Kayu Tidak Bisa Tutup',
            'description' => 'Pintu kamar mandi tidak bisa ditutup rapat. Engsel pintu longgar dan perlu diperbaiki.',
            'category' => 'Perbaikan & Perawatan Rumah',
            'location' => 'Gresik, Jawa Timur',
            'latitude' => -7.1550,
            'longitude' => 112.6561,
            'location_description' => 'Rumah berada di jalan utama. Pintu depan berwarna cokelat dan rumah berada di sebelah rumah dengan pagar putih.',
            'image_url' => null,
            'initial_budget' => 70000,
            'final_price' => null,
            'duration' => '2–3 Hari',
            'started_at' => null,
            'completed_at' => null,
            'status' => 'Mencari Mitra',
            'is_verified' => 0,
            'verified_by' => null,
        ]);
    }
}