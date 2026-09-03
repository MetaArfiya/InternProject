<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ActivityLog;

class ActivityLogController extends Controller
{
    /**
     * =========================================================
     * MENGAMBIL SEMUA LOG AKTIVITAS
     * =========================================================
     *
     * Log berasal dari:
     *
     * Super Admin
     * Admin
     * Mitra
     * Pelanggan
     * Sistem
     *
     */
    public function index()
    {
        try {

            $activities = ActivityLog::with([
                'user.role'
            ])
                ->latest()
                ->take(100)
                ->get();

            $formattedActivities = $activities->map(
                function ($activity) {

                    return [
                        'id' => $activity->id,

                        // =================================================
                        // NAMA USER
                        // =================================================
                        'name' =>
                            $activity->user?->name
                            ?? 'Sistem',

                        // =================================================
                        // ROLE DARI TABEL ROLES
                        // =================================================
                        'role' =>
                            $activity->user?->role?->role_name
                            ?? 'Sistem',

                        // =================================================
                        // AKTIVITAS
                        // =================================================
                        'activity' =>
                            $activity->title,

                        // =================================================
                        // DETAIL
                        // =================================================
                        'detail' =>
                            $activity->detail ?? '',

                        // =================================================
                        // TYPE
                        // =================================================
                        'type' =>
                            $activity->type ?? 'Sistem',

                        // =================================================
                        // ICON
                        // =================================================
                        'icon' =>
                            $activity->icon ?? 'settings',

                        // =================================================
                        // WAKTU
                        // =================================================
                        'time' =>
                            $activity->created_at
                            ? $activity->created_at
                                ->format('d M Y, H:i')
                            : '-',

                        // =================================================
                        // TIMESTAMP
                        // =================================================
                        'created_at' =>
                            $activity->created_at,
                    ];
                }
            );

            return response()->json([
                'success' => true,

                'message' =>
                    'Berhasil mengambil log aktivitas.',

                'data' =>
                    $formattedActivities,

            ], 200);

        } catch (\Exception $e) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Gagal mengambil log aktivitas.',

                'error' =>
                    $e->getMessage(),

            ], 500);
        }
    }


    /**
     * =========================================================
     * MENYIMPAN LOG AKTIVITAS
     * =========================================================
     *
     * Endpoint ini sebenarnya opsional.
     *
     * Aktivitas penting sebaiknya dicatat langsung
     * dari controller masing-masing menggunakan ActivityLogger.
     *
     */
    public function store(Request $request)
    {
        $request->validate([
            'title' =>
                'required|string',

            'detail' =>
                'nullable|string',

            'icon' =>
                'nullable|string',

            'type' =>
                'nullable|string',
        ]);

        $user = $request->user();

        if (!$user) {

            return response()->json([
                'success' => false,

                'message' =>
                    'User belum terautentikasi.',
            ], 401);
        }

        $activity = ActivityLog::create([
            'user_id' =>
                $user->id,

            'title' =>
                $request->title,

            'detail' =>
                $request->detail,

            'icon' =>
                $request->icon ?? 'settings',

            'type' =>
                $request->type ?? 'Sistem',
        ]);

        return response()->json([
            'success' => true,

            'message' =>
                'Aktivitas berhasil dicatat.',

            'data' =>
                $activity,

        ], 201);
    }
}