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

    /**
     * Membatasi pengaduan berdasarkan wilayah admin.
     *
     * Super Admin: seluruh wilayah.
     * Admin: hanya wilayah yang ditugaskan kepadanya.
     */
    private function applyAdminCityScope($query, $admin)
    {
        $role = $this->roleName($admin);

        // Super Admin dapat melihat seluruh wilayah.
        if ($role === 'Super Admin') {
            return $query;
        }

        // Admin tanpa wilayah tidak boleh melihat pengaduan apa pun.
        if (!$admin->city_id) {
            return $query->whereRaw('1 = 0');
        }

        $cityId = $admin->city_id;

        return $query->where(function ($q) use ($cityId) {

            // Pengaduan terkait pekerjaan: gunakan wilayah pekerjaan.
            $q->where(function ($sub) use ($cityId) {
                $sub->whereNotNull('job_id')
                    ->whereHas('job', function ($job) use ($cityId) {
                        $job->where('city_id', $cityId);
                    });
            })

                // Pengaduan umum: gunakan wilayah pelapor.
                ->orWhere(function ($sub) use ($cityId) {
                    $sub->whereNull('job_id')
                        ->whereHas('user', function ($user) use ($cityId) {
                            $user->where('city_id', $cityId);
                        });
                });
        });
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
                'proof_photo' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
            ]);

            $user = auth()->user();
            $role = $this->roleName($user);

            // =====================================================
            // VALIDASI KATEGORI WAJIB JOB (role-aware)
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
            // =====================================================
            if ($request->job_id) {
                $job = jobs::find($request->job_id);

                if (!$job) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Pekerjaan tidak ditemukan.',
                    ], 404);
                }

                if (
                    $role === 'Pelanggan'
                    && (int) $job->pelanggan_id !== (int) $user->id
                ) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Pekerjaan tersebut bukan milik Anda.',
                    ], 403);
                }

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
            // UPLOAD BUKTI FOTO (jika ada) ← INI YANG HILANG
            // =====================================================
            $proofPhotoPath = null;

            if ($request->hasFile('proof_photo')) {
                $proofPhotoPath = $request->file('proof_photo')
                    ->store('complaints', 'public');
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
                'proof_photo' => $proofPhotoPath,
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

    // =========================================================
    // DETAIL PENGADUAN
    // GET /complaints/{id}
    // =========================================================
    public function show($id)
    {
        try {
            $user = auth()->user();
            $role = $this->roleName($user);

            $complaint = Complaint::with([
                'job:id,tittle,city_id',
                'user:id,name,email,city_id',
                'handler:id,name',
            ])->find($id);

            if (!$complaint) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengaduan tidak ditemukan.',
                ], 404);
            }

            $isOwner = (int) $complaint->user_id === (int) $user->id;

            if ($isOwner) {
                return response()->json([
                    'success' => true,
                    'data' => $complaint,
                ], 200);
            }

            if (!in_array($role, ['Admin', 'Super Admin'], true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak berhak melihat pengaduan ini.',
                ], 403);
            }

            // Periksa apakah pengaduan masuk wilayah admin.
            $accessQuery = Complaint::where('id', $id);

            $this->applyAdminCityScope($accessQuery, $user);

            if (!$accessQuery->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak memiliki akses ke pengaduan wilayah ini.',
                ], 403);
            }

            return response()->json([
                'success' => true,
                'data' => $complaint,
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
            $admin = auth()->user();
            $role = $this->roleName($admin);

            if (!in_array($role, ['Admin', 'Super Admin'], true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak memiliki akses.',
                ], 403);
            }

            $baseQuery = Complaint::query();

            $this->applyAdminCityScope($baseQuery, $admin);

            // Summary berdasarkan wilayah admin.
            $summary = [
                'total' => (clone $baseQuery)->count(),

                'menunggu' => (clone $baseQuery)
                    ->where('status', 'Menunggu')->count(),

                'diproses' => (clone $baseQuery)
                    ->where('status', 'Diproses')->count(),

                'selesai' => (clone $baseQuery)
                    ->where('status', 'Selesai')->count(),

                'ditolak' => (clone $baseQuery)
                    ->where('status', 'Ditolak')->count(),
            ];

            // Daftar pengaduan.
            $query = (clone $baseQuery)->with([
                'user:id,name,email,city_id',
                'job:id,tittle,city_id',
            ]);

            if ($request->filled('status') && $request->status !== 'all') {
                $query->where('status', $request->status);
            }

            $complaints = $query->latest()->get();

            return response()->json([
                'success' => true,
                'summary' => $summary,
                'data' => $complaints,
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
            $admin = auth()->user();
            $role = $this->roleName($admin);

            if (!in_array($role, ['Admin', 'Super Admin'], true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak memiliki akses.',
                ], 403);
            }

            // Cari pengaduan sesuai wilayah admin.
            $query = Complaint::query();

            $this->applyAdminCityScope($query, $admin);

            $complaint = $query->find($id);

            if (!$complaint) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengaduan tidak ditemukan atau bukan wilayah Anda.',
                ], 404);
            }

            $request->validate([
                'status' => 'required|in:Menunggu,Diproses,Selesai,Ditolak',
                'admin_response' => 'nullable|string|max:2000',
            ]);

            $current = $complaint->status;
            $next = $request->status;

            if (
                in_array($current, ['Selesai', 'Ditolak'], true)
                && $next === 'Menunggu'
            ) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengaduan yang sudah final tidak bisa dikembalikan ke Menunggu.',
                ], 422);
            }

            if (
                in_array($next, ['Selesai', 'Ditolak'], true)
                && !$request->filled('admin_response')
            ) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tanggapan admin wajib diisi untuk status Selesai/Ditolak.',
                    'errors' => [
                        'admin_response' => [
                            'Tanggapan admin wajib diisi.',
                        ],
                    ],
                ], 422);
            }

            $complaint->update([
                'status' => $next,
                'admin_response' => $request->admin_response,
                'handled_by' => $admin->id,
                'handled_at' => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pengaduan berhasil ditanggapi.',
                'data' => $complaint->fresh()->load([
                    'job:id,tittle,city_id',
                    'user:id,name,email,city_id',
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
