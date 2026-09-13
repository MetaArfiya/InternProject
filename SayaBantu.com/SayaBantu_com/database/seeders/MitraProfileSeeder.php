<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\mitra_profiles;

class MitraProfileSeeder extends Seeder
{
    public function run(): void
    {
        // User ID 5-7: Terverifikasi
        mitra_profiles::create([
            'user_id' => 5,
            'gender' => null,
            'birth_date' => null,
            'city' => null,
            'bank_name' => 'BCA',
            'bank_account_number' => '5555555555',
            'bank_account_name' => 'Budi Setyawan',
            'bio' => 'Berpengalaman lebih dari 5 tahun...',
            'skills' => 'Instalasi & Teknisi',
            'verification_image' => null,
            'selfie_image' => null,
            'certificate' => null,
            'skill_photos' => null,
            'point' => 248,
            'rating' => 4.9,
            'is_verified' => 1,
            'verified_by' => 2,
            'verified_at' => now(),
        ]);

        mitra_profiles::create([
            'user_id' => 6,
            'gender' => null,
            'birth_date' => null,
            'city' => null,
            'bank_name' => 'Mandiri',
            'bank_account_number' => '6666666666',
            'bank_account_name' => 'Eko Prasetyo',
            'bio' => 'Spesialis perbaikan AC, teknisi kulkas...',
            'skills' => 'Instalasi & Teknisi',
            'verification_image' => 'ktp_eko.jpg',
            'certificate' => json_encode(['sertifikat1.jpg', 'sertifikat2.jpg']),
            'point' => 182,
            'rating' => 4.7,
            'is_verified' => 1,
            'verified_by' => 2,
            'verified_at' => now(),
        ]);

        mitra_profiles::create([
            'user_id' => 7,
            'gender' => null,
            'birth_date' => null,
            'city' => null,
            'bank_name' => 'BRI',
            'bank_account_number' => '7777777777',
            'bank_account_name' => 'Joko Wirawan',
            'bio' => 'Teknisi pendingin ruangan...',
            'skills' => 'Instalasi & Teknisi',
            'verification_image' => 'ktp_joko.jpg',
            'point' => 97,
            'rating' => 4.5,
            'is_verified' => 1,
            'verified_by' => 2,
            'verified_at' => now(),
        ]);

        // User ID 8-10: Belum Terverifikasi
        mitra_profiles::create([
            'user_id' => 8,
            'bank_name' => 'BNI',
            'bank_account_number' => '8888888888',
            'bank_account_name' => 'Ahmad Fauzi',
            'bio' => 'Teknisi elektronik muda...',
            'skills' => 'Instalasi & Teknisi',
            'verification_image' => 'ktp_ahmad.jpg',
            'certificate' => json_encode(['berkas_ahmad.jpg']),
            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
        ]);

        mitra_profiles::create([
            'user_id' => 9,
            'bank_name' => 'BCA',
            'bank_account_number' => '9999999999',
            'bank_account_name' => 'Dewi Lestari',
            'bio' => 'Layanan perbaikan pipa bocor...',
            'skills' => 'Perbaikan & Perawatan Rumah',
            'verification_image' => 'ktp_dewi.jpg',
            'certificate' => json_encode(['berkas_dewi.jpg']),
            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
        ]);

        mitra_profiles::create([
            'user_id' => 10,
            'bank_name' => 'CIMB Niaga',
            'bank_account_number' => '1010101010',
            'bank_account_name' => 'Rudi Hartono',
            'bio' => 'Tukang kayu dan perbaikan bangunan...',
            'skills' => 'Konstruksi & Renovasi',
            'verification_image' => 'ktp_rudi.jpg',
            'certificate' => json_encode(['berkas_rudi.jpg']),
            'point' => 0,
            'rating' => 0.0,
            'is_verified' => 0,
        ]);
    }
}