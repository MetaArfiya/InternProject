<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\job_bids;
use App\Models\jobs;

class JobBidSeeder extends Seeder
{
    public function run(): void
    {
        // Cari data ID lowongan secara dinamis berdasarkan judul yang ada di JobSeeder
        $jobAc        = jobs::where('tittle', 'like', '%AC Bocor%')->first();
        $jobKran      = jobs::where('tittle', 'like', '%Kran Air%')->first();
        $jobCat       = jobs::where('tittle', 'like', '%Cat Ulang%')->first();
        $jobPintu     = jobs::where('tittle', 'like', '%Pintu%')->first();
        $jobWallpaper = jobs::where('tittle', 'like', '%Wallpaper%')->first();
        $jobKulkas    = jobs::where('tittle', 'like', '%Kulkas%')->first();

        // --- Lowongan: Service AC Bocor di Ruang Tamu (2 sudah nawar) ---
        if ($jobAc) {
            job_bids::create(['job_id' => $jobAc->id, 'mitra_id' => 5, 'offered_price' => 150000, 'status' => 'Menunggu']);
            job_bids::create(['job_id' => $jobAc->id, 'mitra_id' => 7, 'offered_price' => 145000, 'status' => 'Menunggu']);
        }

        // --- Lowongan: Cat Ulang Kamar Tidur 3x4m (4 sudah nawar) ---
        if ($jobCat) {
            job_bids::create(['job_id' => $jobCat->id, 'mitra_id' => 5, 'offered_price' => 320000, 'status' => 'Menunggu']);
            job_bids::create(['job_id' => $jobCat->id, 'mitra_id' => 7, 'offered_price' => 310000, 'status' => 'Menunggu']);
            job_bids::create(['job_id' => $jobCat->id, 'mitra_id' => 8, 'offered_price' => 300000, 'status' => 'Menunggu']);
            job_bids::create(['job_id' => $jobCat->id, 'mitra_id' => 9, 'offered_price' => 325000, 'status' => 'Menunggu']);
        }

        // --- Lowongan: Perbaikan Pintu Kayu Tidak Bisa Tutup (1 sudah nawar) ---
        if ($jobPintu) {
            job_bids::create(['job_id' => $jobPintu->id, 'mitra_id' => 5, 'offered_price' => 70000, 'status' => 'Menunggu']);
        }

        // --- Halaman Penawaran Aktif Mas Eko: Pasang Wallpaper Ruang Keluarga (Status: Menunggu) ---
        if ($jobWallpaper) {
            job_bids::create(['job_id' => $jobWallpaper->id, 'mitra_id' => 5, 'offered_price' => 280000, 'status' => 'Menunggu']);
            job_bids::create(['job_id' => $jobWallpaper->id, 'mitra_id' => 6, 'offered_price' => 280000, 'status' => 'Menunggu']); // Mas Eko
        }

        // --- Halaman Penawaran Aktif Mas Eko: Service Kulkas Tidak Dingin (Status: Diterima Pelanggan) ---
        if ($jobKulkas) {
            job_bids::create(['job_id' => $jobKulkas->id, 'mitra_id' => 6, 'offered_price' => 185000, 'status' => 'Diterima Pelanggan']); // Mas Eko
        }
    }
}