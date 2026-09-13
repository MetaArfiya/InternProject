<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Rating;

class RatingSeeder extends Seeder
{
    public function run(): void
    {
        // Ambil job yang sudah selesai
        $jobs = \App\Models\jobs::where('status', 'Selesai')
            ->whereNotNull('mitra_id')
            ->get();

        if ($jobs->isEmpty()) {
            $this->command->warn('Tidak ada job "Selesai" — seeder dilewati.');
            return;
        }

        $samples = [
            ['stars' => 5, 'comment' => 'Pelayanan sangat baik, cepat, dan hasil pekerjaannya rapi.'],
            ['stars' => 4, 'comment' => 'Pekerjaan cukup bagus dan mitra sangat ramah.'],
            ['stars' => 3, 'comment' => 'Hasil cukup baik, tetapi datang sedikit terlambat.'],
            ['stars' => 2, 'comment' => 'Hasil kurang rapi dan waktu pengerjaan lama.'],
            ['stars' => 1, 'comment' => 'Pelayanan kurang memuaskan.'],
        ];

        foreach ($jobs as $i => $job) {
            // Skip kalau sudah ada rating
            if (Rating::where('job_id', $job->id)->exists()) {
                continue;
            }

            $sample = $samples[$i % count($samples)];

            Rating::create([
                'job_id'       => $job->id,
                'mitra_id'     => $job->mitra_id,
                'pelanggan_id' => $job->pelanggan_id,
                'stars'        => $sample['stars'],
                'comment'      => $sample['comment'],
                'is_hidden'    => 0,
            ]);
        }

        $this->command->info('RatingSeeder: ' . Rating::count() . ' rating dibuat.');
    }
}