<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StatsController extends Controller
{
    public function getLandingStats()
    {
        try {
            // 1. HITUNG PEKERJAAN SELESAI (Gunakan salah satu atau pastikan tidak ganda)
            // Jika pekerjaan selesai cukup dicek dari tabel jobs yang berstatus Selesai/Done/Completed:
            $completedJobs = DB::table('jobs')
                ->whereIn(DB::raw('LOWER(status)'), ['selesai', 'done', 'completed'])
                ->count();

            // 2. HITUNG MITRA TERVERIFIKASI
            $verifiedMitra = DB::table('mitra_profiles')
                ->where('is_verified', 1)
                ->count();

            // 3. RATING RATA-RATA MITRA
            $avgRating = DB::table('mitra_profiles')
                ->where('is_verified', 1)
                ->where('rating', '>', 0)
                ->avg('rating') ?? 4.9;

            // Hitung total ulasan/reviews
            $totalReviews = \Schema::hasTable('reviews') 
                ? DB::table('reviews')->count() 
                : 0;

            return response()->json([
                'success' => true,
                'data' => [
                    'completed_jobs'     => number_format($completedJobs, 0, ',', '.') . '+',
                    'completed_subtitle' => 'sejak Januari 2024',
                    'verified_mitra'     => number_format($verifiedMitra, 0, ',', '.') . '+',
                    'verified_subtitle'  => 'di berbagai kota',
                    'rating_value'       => number_format($avgRating, 1, '.', '') . ' / 5',
                    'rating_subtitle'    => $totalReviews > 0 
                        ? 'dari ' . number_format($totalReviews, 0, ',', '.') . '+ ulasan' 
                        : 'dari ulasan pelanggan',
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}