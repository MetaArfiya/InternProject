<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\mitra_profiles;

class MitraProfileSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Pak Budi Santoso / Setyawan (User ID: 5) - Terverifikasi
        mitra_profiles::create([
            'user_id' => 5,
            'bio' => 'Berpengalaman lebih dari 5 tahun dalam bidang service AC, instalasi listrik, plumbing, dan perbaikan rumah. Mengutamakan kualitas pekerjaan, ketepatan waktu, serta kepuasan pelanggan.',
            'skills' => 'Service AC, Plumbing, Listrik, Cat Rumah, Perbaikan Kunci',
            'verification_image' => 'ktp_budi.jpg',
            'certificate' => json_encode(['sertifikat_ac_budi.jpg']),
            'point' => 248, 
            'rating' => 4.9,
            'is_verified' => 1,
            'verified_by' => 2,
            'verified_at' => now(),
        ]);

        // 2. Mas Eko Prasetyo (User ID: 6) - Terverifikasi
        mitra_profiles::create([
            'user_id' => 6,
            'bio' => 'Spesialis perbaikan AC, teknisi kulkas profesional, dan ahli pemasangan wallpaper rumah rapi dan bergaransi.',
            'skills' => 'Service AC, Pasang Wallpaper, Service Kulkas',
            'verification_image' => 'ktp_eko.jpg',
            'certificate' => json_encode(['sertifikat1.jpg', 'sertifikat2.jpg', 'sertifikat3.jpg']),
            'point' => 182, 
            'rating' => 4.7,
            'is_verified' => 1,
            'verified_by' => 2,
            'verified_at' => now(),
        ]);

        // 3. Pak Joko Wirawan (User ID: 7) - Terverifikasi
        mitra_profiles::create([
            'user_id' => 7,
            'bio' => 'Teknisi pendingin ruangan dengan pengalaman penanganan berbagai macam kerusakan AC perumahan dan kantor.',
            'skills' => 'Service AC, Bongkar Pasang AC',
            'verification_image' => 'ktp_joko.jpg',
            'certificate' => null,
            'point' => 97, 
            'rating' => 4.5,
            'is_verified' => 1,
            'verified_by' => 2,
            'verified_at' => now(),
        ]);

        // ================= MITRA BELUM VERIFIKASI =================

        // 4. Ahmad Fauzi (User ID: 8) - Belum Terverifikasi
        mitra_profiles::create([
            'user_id' => 8,
            'bio' => 'Teknisi elektronik muda siap membantu perbaikan alat rumah tangga.',
            'skills' => 'AC & Elektronik',
            'verification_image' => 'ktp_ahmad.jpg',
            'certificate' => json_encode(['berkas_ahmad.jpg']),
            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
            'verified_by' => null,
            'verified_at' => null,
        ]);

        // 5. Dewi Lestari (User ID: 9) - Belum Terverifikasi
        mitra_profiles::create([
            'user_id' => 9,
            'bio' => 'Layanan perbaikan pipa bocor dan saluran air tersumbat.',
            'skills' => 'Plumbing',
            'verification_image' => 'ktp_dewi.jpg',
            'certificate' => json_encode(['berkas_dewi.jpg']),
            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
            'verified_by' => null,
            'verified_at' => null,
        ]);

        // 6. Rudi Hartono (User ID: 10) - Belum Terverifikasi
        mitra_profiles::create([
            'user_id' => 10,
            'bio' => 'Tukang kayu dan perbaikan bangunan terpercaya.',
            'skills' => 'Pertukangan',
            'verification_image' => 'ktp_rudi.jpg',
            'certificate' => json_encode(['berkas_rudi.jpg']),
            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
            'verified_by' => null,
            'verified_at' => null,
        ]);
    }
}