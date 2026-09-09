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

            // Kolom baru
            'gender' => null,
            'birth_date' => null,
            'city' => null,

            'bio' => 'Berpengalaman lebih dari 5 tahun dalam bidang service AC, instalasi listrik, plumbing, dan perbaikan rumah. Mengutamakan kualitas pekerjaan, ketepatan waktu, serta kepuasan pelanggan.',
            'skills' => 'Instalasi & Teknisi',

            'verification_image' => null,
            'selfie_image' => null,
            'certificate' => null,
            'skill_photos' => null,

            'point' => 248,
            'rating' => 4.9,
            'is_verified' => 0,
            'verified_by' => null,
            'verified_at' => null,
        ]);

        // 2. Mas Eko Prasetyo (User ID: 6) - Terverifikasi
        mitra_profiles::create([
            'user_id' => 6,

            // Kolom baru
            'gender' => null,
            'birth_date' => null,
            'city' => null,

            'bio' => 'Spesialis perbaikan AC, teknisi kulkas profesional, dan ahli pemasangan wallpaper rumah rapi dan bergaransi.',
            'skills' => 'Instalasi & Teknisi',

            'verification_image' => 'ktp_eko.jpg',
            'selfie_image' => null,
            'certificate' => json_encode([
                'sertifikat1.jpg',
                'sertifikat2.jpg',
                'sertifikat3.jpg'
            ]),
            'skill_photos' => null,

            'point' => 182,
            'rating' => 4.7,
            'is_verified' => 1,
            'verified_by' => 2,
            'verified_at' => now(),
        ]);

        // 3. Pak Joko Wirawan (User ID: 7) - Terverifikasi
        mitra_profiles::create([
            'user_id' => 7,

            // Kolom baru
            'gender' => null,
            'birth_date' => null,
            'city' => null,

            'bio' => 'Teknisi pendingin ruangan dengan pengalaman penanganan berbagai macam kerusakan AC perumahan dan kantor.',
            'skills' => 'Instalasi & Teknisi',

            'verification_image' => 'ktp_joko.jpg',
            'selfie_image' => null,
            'certificate' => null,
            'skill_photos' => null,

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

            // Kolom baru
            'gender' => null,
            'birth_date' => null,
            'city' => null,

            'bio' => 'Teknisi elektronik muda siap membantu perbaikan alat rumah tangga.',
            'skills' => 'Instalasi & Teknisi',

            'verification_image' => 'ktp_ahmad.jpg',
            'selfie_image' => null,
            'certificate' => json_encode(['berkas_ahmad.jpg']),
            'skill_photos' => null,

            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
            'verified_by' => null,
            'verified_at' => null,
        ]);

        // 5. Dewi Lestari (User ID: 9) - Belum Terverifikasi
        mitra_profiles::create([
            'user_id' => 9,

            // Kolom baru
            'gender' => null,
            'birth_date' => null,
            'city' => null,

            'bio' => 'Layanan perbaikan pipa bocor dan saluran air tersumbat.',
            'skills' => 'Perbaikan & Perawatan Rumah',

            'verification_image' => 'ktp_dewi.jpg',
            'selfie_image' => null,
            'certificate' => json_encode(['berkas_dewi.jpg']),
            'skill_photos' => null,

            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
            'verified_by' => null,
            'verified_at' => null,
        ]);

        // 6. Rudi Hartono (User ID: 10) - Belum Terverifikasi
        mitra_profiles::create([
            'user_id' => 10,

            // Kolom baru
            'gender' => null,
            'birth_date' => null,
            'city' => null,

            'bio' => 'Tukang kayu dan perbaikan bangunan terpercaya.',
            'skills' => 'Konstruksi & Renovasi',

            'verification_image' => 'ktp_rudi.jpg',
            'selfie_image' => null,
            'certificate' => json_encode(['berkas_rudi.jpg']),
            'skill_photos' => null,

            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
            'verified_by' => null,
            'verified_at' => null,
        ]);
    }
}