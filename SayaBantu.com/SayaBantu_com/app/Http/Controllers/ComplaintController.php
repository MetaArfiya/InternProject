<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\Complaint;
use App\Models\jobs;
use App\Models\users;

class ComplaintController extends Controller
{
    /**
     * Kategori WAJIB punya job_id — khusus role PELANGGAN.
     */
    private const JOB_REQUIRED_CATEGORIES_PELANGGAN = [
        'Pembayaran',
        'Kualitas Pekerjaan',
        'Mitra Bermasalah',
    ];

    /**
     * Kategori WAJIB punya job_id — khusus role MITRA.
     *
     * Kosong, karena mitra hanya lapor masalah aplikasi
     * (bug, saran fitur) — tidak terkait pekerjaan tertentu.
     */
    private const JOB_REQUIRED_CATEGORIES_MITRA = [];

    /**
     * Ambil nama role dengan aman (lewat relasi).
     */
    private function roleName($user): string
    {
        return $user->role?->role_name
            ?? $user->role_name       // fallback kalau ada accessor
            ?? 'Unknown';
    }

    /**
     * Ambil daftar kategori wajib job sesuai role.
     */
    private function jobRequiredCategories(string $role): array
    {
        return $role === 'Mitra'
            ? self::JOB_REQUIRED_CATEGORIES_MITRA
            : self::JOB_REQUIRED_CATEGORIES_PELANGGAN;
    }

    // =========================================================
    // LIST PENGADUAN MILIK USER (Pelanggan / Mitra / Admin)
    // GET /complaints/my
    // =========================================================
    public function myComplaints()
    {
        try {
            $userId = auth()->id();

            $complaints = Complaint::with(['job:id,tittle'])
                ->where('user_id', $userId)
                ->latest()
                ->get();

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

    // =========================================================
    // BUAT PENGADUAN BARU (Pelanggan / Mitra)
    // POST /complaints
    // =========================================================
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
            $role = $this->roleName($user);

            // =====================================================
            // VALIDASI KATEGORI WAJIB JOB (role-aware)
            // Mitra: array kosong → validasi ini akan skip
            // =====================================================
            $requiredCategories = $this->jobRequiredCategories($role);

            if (
                in_array($request->category, $requiredCategories, true)
                && !$request->job_id
            ) {
                return response()->json([
                    'success' => false,
                    'message' => "Kategori \"{$request->category}\" wajib memilih pekerjaan terkait.",
                    'errors'  => [
                        'job_id' => [
                            "Kategori \"{$request->category}\" wajib memilih pekerjaan terkait.",
                        ],
                    ],
                ], 422);
            }

            // =====================================================
            // VALIDASI JOB MILIK SENDIRI (role-aware)
            // Mitra: skip karena biasanya tidak kirim job_id
            // =====================================================
            if ($request->job_id) {
                $job = jobs::find($request->job_id);

                if (!$job) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Pekerjaan tidak ditemukan.',
                    ], 404);
                }

                // Pelanggan → cek pelanggan_id
                if (
                    $role === 'Pelanggan'
                    && (int) $job->pelanggan_id !== (int) $user->id
                ) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Pekerjaan tersebut bukan milik Anda.',
                    ], 403);
                }

                // Mitra → cek mitra_id
                if (
                    $role === 'Mitra'
                    && (int) $job->mitra_id !== (int) $user->id
                ) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Anda bukan mitra pekerjaan ini.',
                    ], 403);
                }
            }

            // =====================================================
            // SIMPAN
            // =====================================================
            $complaint = Complaint::create([
                'user_id'     => $user->id,
                'user_role'   => $role,
                'category'    => $request->category,
                'title'       => $request->title,
                'description' => $request->description,
                'job_id'      => $request->job_id,
                'status'      => 'Menunggu',
            ]);

            // =====================================================
            // NOTIFIKASI KE ADMIN (opsional)
            // =====================================================
            // try {
            //     $admins = users::whereHas('role', function ($q) {
            //         $q->whereIn('role_name', ['Admin', 'Super Admin']);
            //     })->get();
            //
            //     foreach ($admins as $admin) {
            //         $admin->notify(
            //             new \App\Notifications\NewComplaint($complaint)
            //         );
            //     }
            // } catch (\Exception $e) {
            //     Log::warning('Gagal kirim notif complaint: ' . $e->getMessage());
            // }

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

    // =========================================================
    // DETAIL PENGADUAN
    // GET /complaints/{id}
    // =========================================================
    public function show($id)
    {
        try {
            $complaint = Complaint::with([
                'job:id,tittle',
                'user:id,name,email',
                'handler:id,name',
            ])->find($id);

            if (!$complaint) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengaduan tidak ditemukan.',
                ], 404);
            }

            $userId = auth()->id();
            $role   = $this->roleName(auth()->user());

            $isOwner = (int) $complaint->user_id === (int) $userId;
            $isAdmin = in_array($role, ['Admin', 'Super Admin'], true);

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

    // =========================================================
    // ADMIN — LIST SEMUA PENGADUAN
    // GET /admin/complaints
    // =========================================================
    public function adminIndex(Request $request)
    {
        try {
            $query = Complaint::with([
                'user:id,name,email',
                'job:id,tittle',
            ]);

            if ($request->filled('status') && $request->status !== 'all') {
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

    // =========================================================
    // ADMIN — TANGGAPI PENGADUAN
    // PUT /admin/complaints/{id}
    // =========================================================
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
                'admin_response' => 'nullable|string|max:2000',
            ]);

            // =====================================================
            // VALIDASI TRANSISI STATUS
            // =====================================================
            $current = $complaint->status;
            $next    = $request->status;

            // Yang sudah final tidak boleh balik ke Menunggu
            if (
                in_array($current, ['Selesai', 'Ditolak'], true)
                && $next === 'Menunggu'
            ) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengaduan yang sudah final tidak bisa dikembalikan ke Menunggu.',
                ], 422);
            }

            // Kalau set Selesai/Ditolak, wajib isi admin_response
            if (
                in_array($next, ['Selesai', 'Ditolak'], true)
                && !$request->admin_response
            ) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tanggapan admin wajib diisi untuk status Selesai/Ditolak.',
                    'errors'  => [
                        'admin_response' => [
                            'Tanggapan admin wajib diisi.',
                        ],
                    ],
                ], 422);
            }

            $complaint->update([
                'status'         => $next,
                'admin_response' => $request->admin_response,
                'handled_by'     => auth()->id(),
                'handled_at'     => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pengaduan berhasil ditanggapi.',
                'data'    => $complaint->fresh()->load([
                    'job:id,tittle',
                    'user:id,name,email',
                ]),
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('ComplaintController@adminRespond: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal menanggapi pengaduan.',
            ], 500);
        }
    }
}