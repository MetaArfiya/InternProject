<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use App\Models\ActivityLog;

class ActivityLogController extends Controller
{
    // =============================================================
    // LIST LOG AKTIVITAS
    // GET /api/activity-logs
    // =============================================================
    public function index(Request $request)
    {
        try {
            $query = ActivityLog::with('user:id,name,role_id');

            // Optional: filter by role dari query string
            if ($request->filled('role') && $request->role !== 'all') {
                $roleName = $request->role;
                $query->whereHas('user', function ($q) use ($roleName) {
                    $q->whereHas('role', function ($qr) use ($roleName) {
                        $qr->where('role_name', $roleName);
                    });
                });
            }

            $logs = $query->latest()->get();

            $data = $logs->map(function ($log) {
                $user = $log->user;

                // Tentukan role name
                $roleName = 'Sistem';
                if ($user) {
                    $roleName = $user->role_name ?? 'Pelanggan';
                }

                $time = $log->created_at
                    ? $log->created_at->diffForHumans()
                    : '-';

                return [
                    'id'       => $log->id,
                    'name'     => $user->name ?? 'System',
                    'role'     => $roleName,
                    'activity' => $log->activity ?? $log->title ?? '-',
                    'detail'   => $log->detail ?? $log->description ?? '-',
                    'type'     => $log->type ?? 'Sistem',
                    'icon'     => $log->icon ?? 'history',
                    'time'     => $time,
                ];
            });

            return response()->json([
                'success' => true,
                'data'    => $data,
            ], 200);

        } catch (\Exception $e) {
            Log::error('ActivityLogController@index: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat log aktivitas.',
            ], 500);
        }
    }

    // =============================================================
    // SIMPAN LOG AKTIVITAS
    // POST /api/activity-logs
    // =============================================================
    public function store(Request $request)
    {
        $request->validate([
            'title'  => 'required|string',
            'detail' => 'nullable|string',
            'icon'   => 'nullable|string',
            'type'   => 'nullable|string',
        ]);

        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User belum terautentikasi.',
            ], 401);
        }

        $activity = ActivityLog::create([
            'user_id' => $user->id,
            'title'   => $request->title,
            'detail'  => $request->detail,
            'icon'    => $request->icon ?? 'settings',
            'type'    => $request->type ?? 'Sistem',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Aktivitas berhasil dicatat.',
            'data'    => $activity,
        ], 201);
    }

    // =============================================================
    // HAPUS LOG BERDASARKAN RENTANG WAKTU
    // DELETE /api/activity-logs/by-range?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&role=...
    // =============================================================
    public function deleteByRange(Request $request)
    {
        try {
            $request->validate([
                'start_date' => 'required|date',
                'end_date'   => 'required|date|after_or_equal:start_date',
                'role'       => 'nullable|string',
            ]);

            $startDate = $request->start_date;
            $endDate   = $request->end_date;
            $role      = $request->role;

            $query = ActivityLog::query()
                ->whereDate('created_at', '>=', $startDate)
                ->whereDate('created_at', '<=', $endDate);

            // Optional filter by role
            if (!empty($role) && $role !== 'all' && $role !== 'Semua') {
                if ($role === 'Sistem') {
                    // Log tanpa user → role "Sistem"
                    $query->whereNull('user_id');
                } else {
                    $query->whereHas('user', function ($q) use ($role) {
                        $q->whereHas('role', function ($qr) use ($role) {
                            $qr->where('role_name', $role);
                        });
                    });
                }
            }

            // Hitung dulu sebelum dihapus
            $count = $query->count();

            if ($count === 0) {
                return response()->json([
                    'success' => true,
                    'message' => 'Tidak ada log pada rentang waktu tersebut.',
                    'deleted' => 0,
                ], 200);
            }

            // Hapus
            $query->delete();

            // Catat aktivitas penghapusan
            try {
                \App\Helpers\ActivityLogger::log(
                    auth()->id(),
                    'Menghapus log aktivitas',
                    'Menghapus ' . $count . ' log dari '
                        . $startDate . ' sampai ' . $endDate
                        . (!empty($role) && $role !== 'all' && $role !== 'Semua'
                            ? ' (role: ' . $role . ')'
                            : ''),
                    'delete',
                    'Super Admin'
                );
            } catch (\Exception $logEx) {
                // jangan sampai gagal log membuat proses hapus dianggap gagal
                Log::warning('Gagal mencatat activity log setelah delete: ' . $logEx->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => $count . ' log berhasil dihapus.',
                'deleted' => $count,
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('ActivityLogController@deleteByRange: ' . $e->getMessage());
            Log::error('Stack: ' . $e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus log: ' . $e->getMessage(),
            ], 500);
        }
    }

    // =============================================================
    // HAPUS SEMUA LOG
    // DELETE /api/activity-logs/all
    // =============================================================
    public function deleteAll()
    {
        try {
            $count = ActivityLog::count();

            if ($count === 0) {
                return response()->json([
                    'success' => true,
                    'message' => 'Tidak ada log untuk dihapus.',
                    'deleted' => 0,
                ], 200);
            }

            // Hapus semua
            ActivityLog::query()->delete();

            // Catat aktivitas penghapusan
            try {
                \App\Helpers\ActivityLogger::log(
                    auth()->id(),
                    'Menghapus semua log aktivitas',
                    'Menghapus seluruh ' . $count . ' log aktivitas.',
                    'delete',
                    'Super Admin'
                );
            } catch (\Exception $logEx) {
                Log::warning('Gagal mencatat activity log setelah deleteAll: ' . $logEx->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => $count . ' log berhasil dihapus.',
                'deleted' => $count,
            ], 200);

        } catch (\Exception $e) {
            Log::error('ActivityLogController@deleteAll: ' . $e->getMessage());
            Log::error('Stack: ' . $e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus semua log: ' . $e->getMessage(),
            ], 500);
        }
    }
}