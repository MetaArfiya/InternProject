<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\Complaint;
use App\Models\jobs;

class ComplaintController extends Controller
{
    /**
     * =========================================================
     * LIST PENGADUAN MILIK USER (mitra/pelanggan)
     * GET /complaints/my
     * =========================================================
     */
    public function myComplaints()
    {
        try {
            $userId = auth()->id();
            $user = auth()->user();
            $role = $user->role_name; // ← PERBAIKAN

            $complaints = Complaint::with(['job:id,tittle'])
                ->where('user_id', $userId)
                ->latest()
                ->get();

            // Summary per status
            $summary = [
                'total'     => $complaints->count(),
                'menunggu'  => $complaints->where('status', 'Menunggu')->count(),
                'diproses'  => $complaints->where('status', 'Diproses')->count(),
                'selesai'   => $complaints->where('status', 'Selesai')->count(),
                'ditolak'   => $complaints->where('status', 'Ditolak')->count(),
            ];

            return response()->json([
                'success' => true,
                'summary' => $summary,
                'data'    => $complaints,
            ], 200);

        } catch (\Exception $e) {
            Log::error('ComplaintController@myComplaints: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat pengaduan.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * BUAT PENGADUAN BARU
     * POST /complaints
     * =========================================================
     */
    public function store(Request $request)
    {
        try {
            $request->validate([
                'category'    => 'required|string|max:100',
                'title'       => 'required|string|max:255',
                'description' => 'required|string',
                'job_id'      => 'nullable|integer|exists:jobs,id',
            ]);

            $user = auth()->user();
            $role = $user->role_name; // ← PERBAIKAN (string)

            $complaint = Complaint::create([
                'user_id'     => $user->id,
                'user_role'   => $role,
                'category'    => $request->category,
                'title'       => $request->title,
                'description' => $request->description,
                'job_id'      => $request->job_id,
                'status'      => 'Menunggu',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pengaduan berhasil dikirim.',
                'data'    => $complaint->load('job:id,tittle'),
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('ComplaintController@store: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat pengaduan: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * =========================================================
     * DETAIL PENGADUAN
     * GET /complaints/{id}
     * =========================================================
     */
    public function show($id)
    {
        try {
            $complaint = Complaint::with(['job', 'user:id,name,email', 'handler:id,name'])
                ->find($id);

            if (!$complaint) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengaduan tidak ditemukan.',
                ], 404);
            }

            // Validasi akses
            $userId = auth()->id();
            $role = auth()->user()->role_name; // ← PERBAIKAN (string)

            $isOwner = $complaint->user_id === $userId;
            $isAdmin = in_array($role, ['Admin', 'Super Admin']);

            if (!$isOwner && !$isAdmin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak berhak melihat pengaduan ini.',
                ], 403);
            }

            return response()->json([
                'success' => true,
                'data'    => $complaint,
            ], 200);

        } catch (\Exception $e) {
            Log::error('ComplaintController@show: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat detail pengaduan.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * ADMIN — LIST SEMUA PENGADUAN
     * GET /admin/complaints
     * =========================================================
     */
    public function adminIndex(Request $request)
    {
        try {
            $query = Complaint::with(['user:id,name,email', 'job:id,tittle']);

            if ($request->has('status') && $request->status !== 'all') {
                $query->where('status', $request->status);
            }

            $complaints = $query->latest()->get();

            $summary = [
                'total'     => Complaint::count(),
                'menunggu'  => Complaint::where('status', 'Menunggu')->count(),
                'diproses'  => Complaint::where('status', 'Diproses')->count(),
                'selesai'   => Complaint::where('status', 'Selesai')->count(),
                'ditolak'   => Complaint::where('status', 'Ditolak')->count(),
            ];

            return response()->json([
                'success' => true,
                'summary' => $summary,
                'data'    => $complaints,
            ], 200);

        } catch (\Exception $e) {
            Log::error('ComplaintController@adminIndex: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat pengaduan.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * ADMIN — TANGGAPI PENGADUAN
     * PUT /admin/complaints/{id}
     * =========================================================
     */
    public function adminRespond(Request $request, $id)
    {
        try {
            $complaint = Complaint::find($id);

            if (!$complaint) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengaduan tidak ditemukan.',
                ], 404);
            }

            $request->validate([
                'status'         => 'required|in:Menunggu,Diproses,Selesai,Ditolak',
                'admin_response' => 'nullable|string',
            ]);

            $complaint->update([
                'status'         => $request->status,
                'admin_response' => $request->admin_response,
                'handled_by'     => auth()->id(),
                'handled_at'     => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pengaduan berhasil ditanggapi.',
                'data'    => $complaint->fresh(),
            ], 200);

        } catch (\Exception $e) {
            Log::error('ComplaintController@adminRespond: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal menanggapi pengaduan.',
            ], 500);
        }
    }
}