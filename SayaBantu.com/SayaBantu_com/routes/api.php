<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\JobController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\SuperAdminController;
use App\Http\Controllers\MitraProfileController;
use App\Http\Controllers\NotificationController;
use App\Models\AppReview;
use App\Http\Controllers\StatsController;
use App\Http\Controllers\AdminActivityController;
use App\Http\Controllers\SystemSettingController;
use App\Http\Controllers\ActivityLogController;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Response;

// --- JALUR UMUM (Bebas Akses) ---

// --- SERVE GAMBAR JOB DENGAN CORS ---
Route::get('/images/jobs/{filename}', function ($filename) {

    $path = 'jobs/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json([
            'success' => false,
            'message' => 'Gambar tidak ditemukan.',
        ], 404);
    }

    $file = Storage::disk('public')->get($path);
    $mimeType = Storage::disk('public')->mimeType($path);

    return Response::make($file, 200)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
});

Route::get('/testimonials', function () {
    try {
        $reviews = AppReview::with('user')->latest()->take(3)->get()->map(function ($review) {
            // Ambil nama user (fallback ke 'Pelanggan' jika null)
            $userName = $review->user->name ?? 'Pelanggan';

            // Buat inisial nama untuk avatar
            $words = explode(' ', trim($userName));
            $initials = '';
            foreach ($words as $w) {
                if (!empty($w)) {
                    $initials .= mb_substr($w, 0, 1);
                }
            }
            $avatar = strtoupper(substr($initials, 0, 2));

            // PERBAIKAN: Gunakan empty() khas PHP (bukan .isEmpty)
            if (empty($avatar)) {
                $avatar = 'U';
            }

            return [
                'id' => $review->id,
                'category' => $review->headline_job ?? '',
                'review' => '"' . ($review->comment ?? '') . '"',
                'name' => $userName,
                'job' => $review->profession ?? '',
                'avatar' => $avatar,
                'stars' => $review->stars ?? 5,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'reviews' => $reviews,
                'total_reviews' => number_format(AppReview::count(), 0, ',', '.') . '+',
                'average_rating' => round(AppReview::avg('stars') ?? 5.0, 1),
            ]
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
});

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'resetPassword']);

// Pencarian pada dashboard berdasarkan keyword (bisa diakses oleh semua)
Route::get('/jobs/search', [JobController::class, 'search']);

Route::get('/landing-hero-offers', [JobController::class, 'getHeroData']);

Route::get('/landing-stats', [StatsController::class, 'getLandingStats']);

// --- JALUR YANG HARUS LOGIN (Protected) ---
Route::middleware('auth:sanctum')->group(function () {

    Route::get('/activity-logs', [ActivityLogController::class, 'index']);
    Route::post('/activity-logs', [ActivityLogController::class, 'store']);

    Route::get('/user', [AuthController::class, 'me']);
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);

    // Khusus Role: Super Admin
    Route::middleware('role:Super Admin')->group(function () {
        Route::post('/superadmin/create-admin', [SuperAdminController::class, 'createAdmin']);

        // --- ROUTE BARU ANALYTICS SUPER ADMIN ---
        Route::get('/superadmin/analytics', [SuperAdminController::class, 'analytics']);

        // --- ROUTE BARU MANAJEMEN AKUN ADMIN ---
        Route::get('/superadmin/admins', [SuperAdminController::class, 'getAdmins']);
        Route::put('/superadmin/admins/{id}', [SuperAdminController::class, 'updateAdmin']);
        Route::delete('/superadmin/admins/{id}', [SuperAdminController::class, 'deleteAdmin']);

        // --- ROUTE BARU MANAJEMEN MITRA ---
        Route::get('/superadmin/system-settings', [SuperAdminController::class, 'getSystemSettings']);

        Route::put('/superadmin/system-settings', [SuperAdminController::class, 'updateSystemSettings']);

        // Route::get('/activity-logs', [ActivityLogController::class, 'index']);
        // Route::post('/activity-logs', [ActivityLogController::class, 'store']);
    });

    // Khusus Role: Admin
    Route::middleware('role:Admin')->group(function () {
        Route::get('/admin/unverified-mitra', [AdminController::class, 'unverifiedMitra']);
        Route::post('/admin/verify-mitra/{id}', [AdminController::class, 'verifyMitra']);

        // --- ROUTE BARU MODERASI LOWONGAN KERJA ---
        Route::get('/admin/jobs-moderation', [AdminController::class, 'contentModeration']);
        Route::post('/admin/jobs-moderate/{id}', [AdminController::class, 'moderateJob']);

        Route::get('/admin/activities', [AdminActivityController::class, 'index']);
        Route::post('/admin/activities', [AdminActivityController::class, 'store']);
    });

    // Khusus Role: Mitra (TARUH DI ATAS AGAR DIBACA LEBIH DULU)
    Route::middleware('role:Mitra')->group(function () {
        Route::get('/mitra/available-jobs', [JobController::class, 'availableJobs']);
        Route::get('/mitra/my-offers', [JobController::class, 'myOffers']);
        Route::post('/mitra/upload-ktp', [MitraProfileController::class, 'uploadKtp']);
        
        Route::get('/jobs', [JobController::class, 'index']); 
        Route::post('/jobs/{id}/apply', [JobController::class, 'applyJob']); 
        Route::post('/jobs/{id}/cancel', [JobController::class, 'cancelJob']);
        Route::get('/mitra/profile', [MitraProfileController::class, 'getProfile']);
    });

    // Khusus Role: Pelanggan
    Route::middleware('role:Pelanggan')->group(function () {
        Route::post('/jobs', [JobController::class, 'store']);
        
        // --- ROUTE BARU SELESAI KERJA ---
        Route::post('/jobs/{id}/complete', [JobController::class, 'completeJob']);
        // --- ROUTE BARU RIWAYAT KERJA PELANGGAN ---
        Route::get('/pelanggan/my-jobs', [JobController::class, 'myJobs']);

        // --- ROUTE BARU TERIMA BID ---
        Route::post('/jobs/accept-bid/{bidId}', [JobController::class, "acceptBid"]);

        Route::get('/mitra/{id}', [MitraProfileController::class, 'show']);

        // ROUTE DINAMIS {id} TARUH PALING BAWAH DI GRUP PELANGGAN
        Route::get('/jobs/{id}', [JobController::class, 'show']); 
    });

    // Route::get('/admin/activities', [AdminActivityController::class, 'index']);
    // Route::post('/admin/activities', [AdminActivityController::class, 'store']);

    // --- ROUTE NOTIFIKASI (Bisa diakses Pelanggan & Mitra yang sudah login) --- 
    Route::get('/notifications', [NotificationController::class, 'getNotifications']);
    Route::post('/notifications/mark-as-read', [NotificationController::class, 'markAsRead']);
    Route::put('/user/notification-setting', [AuthController::class, 'updateNotificationSetting']);

    Route::post('/change-password', [AuthController::class, 'changePassword']);
});