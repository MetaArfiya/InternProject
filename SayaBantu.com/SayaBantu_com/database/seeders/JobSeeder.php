<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\jobs;
use App\Models\users;

class JobSeeder extends Seeder
{
    public function run(): void
    {
        // Ambil user pelanggan (Budi Santoso) sebagai pembuat lowongan
        $pelanggan = users::where('name', 'Budi Santoso')->first();
        $pelangganId = $pelanggan ? $pelanggan->id : 4;

        // Ambil user yang memiliki role Admin / Super Admin untuk kolom verified_by
        $admin = users::whereHas('role', function ($q) {
            $q->where('role_name', 'Admin')
              ->orWhere('role_name', 'Super Admin');
        })->first();

        // Fallback ID admin jika tidak ditemukan via relasi
        $adminId = $admin ? $admin->id : 2;

        jobs::create([
            'pelanggan_id'   => $pelangganId,
            'tittle'         => 'Service AC Bocor di Ruang Tamu',
            'description'    => 'AC 1 PK merek Sharp, bocor terus dari bagian atas. Sudah dibersihkan tapi masih bocor.',
            'category'       => 'Instalasi & Teknisi',
            'location'       => 'Sidoarjo, Jawa Timur',
            'initial_budget' => 150000,
            'status'         => 'Mencari Mitra',
            'is_verified'    => 0,
            'verified_by'    => null,
        ]);

        jobs::create([
            'pelanggan_id'   => $pelangganId,
            'tittle'         => 'Pasang Kran Air Dapur Bocor',
            'description'    => 'Kran dapur bocor parah, air terus menetes. Perlu penggantian kran baru.',
            'category'       => 'Instalasi & Teknisi',
            'location'       => 'Surabaya Barat',
            'initial_budget' => 95000,
            'status'         => 'Mencari Mitra',
            'is_verified'    => 0,
            'verified_by'    => null,
        ]);

        jobs::create([
            'pelanggan_id'   => $pelangganId,
            'tittle'         => 'Cat Ulang Kamar Tidur 3x4m',
            'description'    => 'Kamar tidur perlu dicat ulang, warna putih bersih. Cat dan peralatan disediakan.',
            'category'       => 'Perbaikan & Perawatan Rumah',
            'location'       => 'Surabaya Timur',
            'initial_budget' => 320000,
            'status'         => 'Mencari Mitra',
            'is_verified'    => 0,
            'verified_by'    => null,
        ]);

        jobs::create([
            'pelanggan_id'   => $pelangganId,
            'tittle'         => 'Perbaikan Pintu Kayu Tidak Bisa Tutup',
            'description'    => 'Pintu kamar mandi tidak bisa ditutup rapat, engsel longgar.',
            'category'       => 'Perbaikan & Perawatan Rumah',
            'location'       => 'Gresik, Jawa Timur',
            'initial_budget' => 70000,
            'status'         => 'Mencari Mitra',
            'is_verified'    => 0,
            'verified_by'    => null,
        ]);
    }
}