<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ActivityLog;
use App\Models\users;

class AdminActivityController extends Controller
{
    // =========================================================
    // MENGAMBIL LAPORAN AKTIVITAS ADMIN HARI INI
    // =========================================================

    public function index()
    {
        try {

            // =====================================================
            // AKTIVITAS ADMIN HARI INI
            // =====================================================

            $activities = ActivityLog::with('user')
                ->whereDate('created_at', today())
                ->whereHas('user', function ($query) {
                    $query->where('role_id', 2);
                })
                ->latest()
                ->take(50)
                ->get();


            // =====================================================
            // STATISTIK
            // =====================================================

            $approvedPartners = ActivityLog::whereDate(
                    'created_at',
                    today()
                )
                ->where('icon', 'verified')
                ->whereHas('user', function ($query) {
                    $query->where('role_id', 2);
                })
                ->count();


            $moderatedPosts = ActivityLog::whereDate(
                    'created_at',
                    today()
                )
                ->where('icon', 'flag')
                ->whereHas('user', function ($query) {
                    $query->where('role_id', 2);
                })
                ->count();


            $rejectedPosts = ActivityLog::whereDate(
                    'created_at',
                    today()
                )
                ->where('icon', 'cancel')
                ->whereHas('user', function ($query) {
                    $query->where('role_id', 2);
                })
                ->count();


            $userReports = ActivityLog::whereDate(
                    'created_at',
                    today()
                )
                ->where('icon', 'report')
                ->whereHas('user', function ($query) {
                    $query->where('role_id', 2);
                })
                ->count();


            // =====================================================
            // FORMAT UNTUK FLUTTER
            // =====================================================

            $formattedActivities = $activities->map(
                function ($activity) {

                    return [
                        'id' => $activity->id,

                        'title' =>
                            $activity->title,

                        'detail' =>
                            $activity->detail,

                        'icon' =>
                            $activity->icon,

                        'color_type' =>
                            $this->getColorType(
                                $activity->icon
                            ),

                        'time' =>
                            $activity->created_at
                                ? $activity->created_at->format('H:i')
                                : '-',

                        'admin_name' =>
                            $activity->user?->name,
                    ];
                }
            );


            // =====================================================
            // RESPONSE
            // =====================================================

            return response()->json([
                'success' => true,

                'message' =>
                    'Berhasil mengambil laporan aktivitas admin.',

                'data' => [

                    'statistics' => [

                        'approved_partners' =>
                            $approvedPartners,

                        'moderated_posts' =>
                            $moderatedPosts,

                        'rejected_posts' =>
                            $rejectedPosts,

                        'user_reports' =>
                            $userReports,
                    ],

                    'activities' =>
                        $formattedActivities,
                ],

            ], 200);

        } catch (\Exception $e) {

            return response()->json([

                'success' => false,

                'message' =>
                    'Gagal mengambil data aktivitas.',

                'error' =>
                    $e->getMessage(),

            ], 500);
        }
    }


    // =========================================================
    // MENENTUKAN WARNA BERDASARKAN ICON
    // =========================================================

    private function getColorType($icon)
    {
        switch ($icon) {

            case 'verified':
            case 'check':
                return 'green';

            case 'flag':
                return 'purple';

            case 'cancel':
                return 'red';

            case 'report':
                return 'orange';

            default:
                return 'gray';
        }
    }


    // =========================================================
    // MENYIMPAN AKTIVITAS ADMIN
    // =========================================================

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


        $activity = ActivityLog::create([

            'user_id' =>
                $request->user()->id,

            'title' =>
                $request->title,

            'detail' =>
                $request->detail,

            'icon' =>
                $request->icon ?? 'check',

            'type' =>
                $request->type ?? 'Admin',

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