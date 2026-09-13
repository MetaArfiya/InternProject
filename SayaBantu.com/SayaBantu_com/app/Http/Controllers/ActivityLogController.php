<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;  // ← FIX: import Log
use App\Models\ActivityLog;

class ActivityLogController extends Controller
{
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
                        // kalau field-nya 'name', tambah ->orWhere('name', $roleName)
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
}