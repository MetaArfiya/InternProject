<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ActivityLog;
use App\Models\users;

class AdminActivityController extends Controller
{
    use \App\Http\Controllers\Concerns\EnforcesAdminCity;

    private function scopedAdminActivities($admin)
    {
        return ActivityLog::whereHas('user', function ($query) use ($admin) {
            $query->where('role_id', 2);
            if ($cityId = $this->adminCityId($admin)) {
                $query->where('city_id', $cityId);
            }
        });
    }

    // =========================================================
    // MENGAMBIL LAPORAN AKTIVITAS ADMIN HARI INI
    // =========================================================

    public function index()
    {
        try {
            $admin = auth()->user();
            if ($response = $this->missingAdminCityResponse($admin)) {
                return $response;
            }

            // =====================================================
            // AKTIVITAS ADMIN HARI INI
            // =====================================================

            $activities = $this->scopedAdminActivities($admin)
                ->with('user')
                ->whereDate('created_at', today())
                ->latest()
                ->take(50)
                ->get();


            // =====================================================
            // STATISTIK
            // =====================================================

            $approvedPartners = $this->scopedAdminActivities($admin)->whereDate(
                    'created_at',
                    today()
                )
                ->where('icon', 'verified')
                ->count();


            $moderatedPosts = $this->scopedAdminActivities($admin)->whereDate(
                    'created_at',
                    today()
                )
                ->where('icon', 'flag')
                ->count();


            $rejectedPosts = $this->scopedAdminActivities($admin)->whereDate(
                    'created_at',
                    today()
                )
                ->where('icon', 'cancel')
                ->count();


            $userReports = $this->scopedAdminActivities($admin)->whereDate(
                    'created_at',
                    today()
                )
                ->where('icon', 'report')
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
                            ? $activity->created_at->copy()->timezone(config('app.timezone'))->format('H:i')
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
