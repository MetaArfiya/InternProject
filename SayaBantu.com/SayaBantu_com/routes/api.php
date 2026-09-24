<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Response;

use App\Http\Controllers\AuthController;
use App\Http\Controllers\JobController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\SuperAdminController;
use App\Http\Controllers\MitraProfileController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\StatsController;
use App\Http\Controllers\AdminActivityController;
use App\Http\Controllers\SystemSettingController;
use App\Http\Controllers\ActivityLogController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ComplaintController;
use App\Http\Controllers\RatingController;
use App\Models\AppReview;


// =========================================================
// JALUR UMUM / PUBLIC
// =========================================================

Route::get('/images/jobs/{filename}', function ($filename) {
    $path = 'jobs/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json([
            'success' => false,
            'message' => 'Gambar tidak ditemukan.',
        ], 404);
    }

    $file = Storage::disk('public')->get($path);
    $mimeType = match (strtolower(pathinfo($filename, PATHINFO_EXTENSION))) {
        'jpg', 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        default => 'application/octet-stream',
    };

    return Response::make($file, 200)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
});


Route::get('/images/profile/{filename}', function ($filename) {
    $path = 'profile_photos/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json([
            'success' => false,
            'message' => 'Foto profil tidak ditemukan.',
        ], 404);
    }

    $file = Storage::disk('public')->get($path);
    $mimeType = match (strtolower(pathinfo($filename, PATHINFO_EXTENSION))) {
        'jpg', 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        default => 'application/octet-stream',
    };

    return Response::make($file, 200)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*')
        ->header('Cache-Control', 'no-cache, no-store, must-revalidate');
});


Route::get('/images/skill_photos/{filename}', function ($filename) {
    $path = 'skill_photos/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json([
            'success' => false,
            'message' => 'Gambar skill tidak ditemukan.',
        ], 404);
    }

    $file = Storage::disk('public')->get($path);
    $mimeType = match (strtolower(pathinfo($filename, PATHINFO_EXTENSION))) {
        'jpg', 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        default => 'application/octet-stream',
    };

    return Response::make($file, 200)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
});


Route::get('/images/certificates/{filename}', function ($filename) {
    $path = 'certificates/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json([
            'success' => false,
            'message' => 'Sertifikat tidak ditemukan.',
        ], 404);
    }

    $file = Storage::disk('public')->get($path);
    $mimeType = match (strtolower(pathinfo($filename, PATHINFO_EXTENSION))) {
        'jpg', 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        default => 'application/octet-stream',
    };

    return Response::make($file, 200)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
});


Route::get('/images/completion_proofs/{filename}', function ($filename) {
    $path = 'completion_proofs/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json([
            'success' => false,
            'message' => 'Bukti pekerjaan tidak ditemukan.',
        ], 404);
    }

    $file = Storage::disk('public')->get($path);
    $mimeType = match (strtolower(pathinfo($filename, PATHINFO_EXTENSION))) {
        'jpg', 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        default => 'application/octet-stream',
    };

    return Response::make($file, 200)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
});


Route::get('/images/payment_proofs/{folder}/{filename}', function ($folder, $filename) {
    if (!in_array($folder, ['customer', 'mitra'])) {
        return response()->json([
            'success' => false,
            'message' => 'Folder tidak valid.',
        ], 400);
    }

    $path = 'payment_proofs/' . $folder . '/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json([
            'success' => false,
            'message' => 'Bukti pembayaran tidak ditemukan.',
        ], 404);
    }

    $file = Storage::disk('public')->get($path);
    $mimeType = match (strtolower(pathinfo($filename, PATHINFO_EXTENSION))) {
        'jpg', 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        default => 'application/octet-stream',
    };

    return Response::make($file, 200)
        ->header('Content-Type', $mimeType)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
});


Route::get('/testimonials', function () {
    try {
        $reviews = AppReview::with('user')
            ->latest()
            ->take(3)
            ->get()
            ->map(function ($review) {
                $userName = $review->user->name ?? 'Pelanggan';
                $words = explode(' ', trim($userName));
                $initials = '';
                foreach ($words as $w) {
                    if (!empty($w)) {
                        $initials .= mb_substr($w, 0, 1);
                    }
                }
                $avatar = strtoupper(substr($initials, 0, 2));
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


// =========================================================
// AUTH PUBLIC
// =========================================================

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'resetPassword']);


// =========================================================
// SEARCH JOB
// =========================================================

Route::get('/jobs/search', [JobController::class, 'search']);


// =========================================================
// LANDING
// =========================================================

Route::get('/landing-hero-offers', [JobController::class, 'getHeroData']);
Route::get('/landing-stats', [StatsController::class, 'getLandingStats']);


// =========================================================
// PROTECTED ROUTES
// =========================================================

Route::middleware('auth:sanctum')->group(function () {

    Route::get('/user', [AuthController::class, 'me']);
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
    Route::post('/user/profile/photo', [AuthController::class, 'uploadProfilePhoto']);


    Route::get('/activity-logs', [ActivityLogController::class, 'index']);
    Route::post('/activity-logs', [ActivityLogController::class, 'store']);

    Route::delete('/activity-logs/by-range', [ActivityLogController::class, 'deleteByRange']);
    Route::delete('/activity-logs/all',      [ActivityLogController::class, 'deleteAll']);


    Route::get('/complaints/my',    [ComplaintController::class, 'myComplaints']);
    Route::post('/complaints',      [ComplaintController::class, 'store']);
    Route::get('/complaints/{id}',  [ComplaintController::class, 'show']);


    Route::get('/payments/{id}', [PaymentController::class, 'show']);


    Route::get('/notifications', [NotificationController::class, 'getNotifications']);
    Route::post('/notifications/mark-as-read', [NotificationController::class, 'markAsRead']);
    Route::put('/user/notification-setting', [AuthController::class, 'updateNotificationSetting']);


    Route::post('/change-password', [AuthController::class, 'changePassword']);


    // =====================================================
    // SUPER ADMIN
    // =====================================================
    Route::middleware('role:Super Admin')->group(function () {
        Route::post('/superadmin/create-admin', [SuperAdminController::class, 'createAdmin']);
        Route::get('/superadmin/analytics', [SuperAdminController::class, 'analytics']);
        Route::get('/superadmin/admins', [SuperAdminController::class, 'getAdmins']);
        Route::put('/superadmin/admins/{id}', [SuperAdminController::class, 'updateAdmin']);
        Route::delete('/superadmin/admins/{id}', [SuperAdminController::class, 'deleteAdmin']);
        Route::get('/superadmin/system-settings', [SuperAdminController::class, 'getSystemSettings']);
        Route::put('/superadmin/system-settings', [SuperAdminController::class, 'updateSystemSettings']);

        Route::post('/superadmin/settings/bank-account', [SuperAdminController::class, 'updateBankAccount']);

        Route::get('/superadmin/active-partners', [SuperAdminController::class, 'activePartners']);

        Route::get('/superadmin/payments/overview',  [PaymentController::class, 'superOverview']);
        Route::get('/superadmin/payments/chart',     [PaymentController::class, 'superChart']);
        Route::get('/superadmin/payments/top-mitra', [PaymentController::class, 'superTopMitra']);
    });


    // =====================================================
    // ADMIN
    // =====================================================
        // =====================================================
    // ADMIN
    // =====================================================
    Route::middleware('role:Admin')->group(function () {
        Route::get('/admin/unverified-mitra', [AdminController::class, 'unverifiedMitra']);
        Route::post('/admin/verify-mitra/{id}', [AdminController::class, 'verifyMitra']);
        Route::get('/admin/jobs-moderation', [AdminController::class, 'contentModeration']);
        Route::post('/admin/jobs-moderate/{id}', [AdminController::class, 'moderateJob']);
        Route::get('/admin/activities', [AdminActivityController::class, 'index']);
        Route::post('/admin/activities', [AdminActivityController::class, 'store']);

        // PEMBAYARAN — ADMIN
        Route::get('/admin/payments',                    [PaymentController::class, 'adminIndex']);
        Route::get('/admin/payments/{id}',               [PaymentController::class, 'showForAdmin']);
        Route::put('/admin/payments/{id}/verify',        [PaymentController::class, 'verifyCustomerProof']);
        Route::post('/admin/payments/{id}/settle',       [PaymentController::class, 'settle']);
        Route::put('/admin/payments/{id}/refund',        [PaymentController::class, 'refund']);

        // COMPLAINTS — ADMIN
        Route::get('/admin/complaints',         [ComplaintController::class, 'adminIndex']);
        Route::put('/admin/complaints/{id}',    [ComplaintController::class, 'adminRespond']);

        // Laporan harian
        Route::get('/admin/daily-report', [AdminController::class, 'dailyReport']);

        // RATING — ADMIN
        Route::get('/admin/ratings',             [RatingController::class, 'adminIndex']);
        Route::get('/admin/ratings/{id}',        [RatingController::class, 'show']);
        Route::delete('/admin/ratings/{id}',     [RatingController::class, 'destroy']);
        Route::put('/admin/ratings/{id}/hide',   [RatingController::class, 'hide']);
        Route::put('/admin/ratings/{id}/unhide', [RatingController::class, 'unhide']);

        Route::get('/admin/verified-mitra', [AdminController::class, 'verifiedMitra']);

        // 🆕 PERUBAHAN KEAHLIAN MITRA
        Route::get('/admin/pending-skills', [MitraProfileController::class, 'pendingSkills']);
        Route::post('/admin/approve-skill/{mitraId}', [MitraProfileController::class, 'approveSkill']);
        Route::post('/admin/reject-skill/{mitraId}',  [MitraProfileController::class, 'rejectSkill']);
    });


    // =====================================================
    // MITRA
    // =====================================================
    Route::middleware('role:Mitra')->group(function () {
        Route::post('/mitra/verification', [MitraProfileController::class, 'submitVerification']);
        Route::post('/mitra/skill-photos', [MitraProfileController::class, 'uploadSkillPhotos']);
        Route::post('/mitra/certificate', [MitraProfileController::class, 'uploadCertificate']);

        Route::get('/mitra/profile', [MitraProfileController::class, 'getProfile']);
        Route::put('/mitra/profile', [MitraProfileController::class, 'updateProfile']);

        Route::post('/mitra/upload-ktp', [MitraProfileController::class, 'uploadKtp']);

        Route::get('/mitra/available-jobs', [JobController::class, 'availableJobs']);
        Route::get('/mitra/my-offers', [JobController::class, 'myOffers']);
        Route::get('/jobs', [JobController::class, 'index']);
        Route::post('/jobs/{id}/apply', [JobController::class, 'applyJob']);
        Route::post('/jobs/{id}/cancel', [JobController::class, 'cancelJob']);

        Route::post('/jobs/{id}/upload-proof', [JobController::class, 'uploadProof']);

        Route::get('/mitra/earnings', [PaymentController::class, 'mitraIndex']);
        Route::get('/mitra/earnings/monthly', [PaymentController::class, 'mitraMonthlyStats']);
    });


    // =====================================================
    // PELANGGAN
    // =====================================================
    Route::middleware('role:Pelanggan')->group(function () {
        Route::post('/jobs', [JobController::class, 'store']);
        Route::get('/pelanggan/my-jobs', [JobController::class, 'myJobs']);
        Route::post('/jobs/accept-bid/{bidId}', [JobController::class, 'acceptBid']);

        Route::post('/jobs/{id}/verify-proof', [JobController::class, 'verifyProof']);

        Route::get('/mitra/{id}', [MitraProfileController::class, 'show']);
        Route::get('/jobs/{id}', [JobController::class, 'show']);

        Route::get('/pelanggan/payments',                   [PaymentController::class, 'pelangganIndex']);
        Route::get('/pelanggan/payments/{id}',              [PaymentController::class, 'showForPelanggan']);
        Route::post('/pelanggan/payments/{id}/upload-proof',[PaymentController::class, 'uploadCustomerProof']);

        Route::post('/pelanggan/ratings',              [RatingController::class, 'storeFromPelanggan']);
        Route::get('/pelanggan/ratings/job/{jobId}',   [RatingController::class, 'checkJobRating']);
    });
});