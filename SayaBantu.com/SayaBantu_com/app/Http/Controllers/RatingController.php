<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\Rating;
use App\Models\mitra_profiles;
use App\Models\Payment;

class RatingController extends Controller
{
    /**
     * =========================================================
     * ADMIN — LIST SEMUA RATING
     * GET /admin/ratings?stars=5&hidden=0
     * =========================================================
     */
    public function adminIndex(Request $request)
    {
        try {
            $query = Rating::with([
                'job:id,tittle',
                'mitra:id,name',
                'pelanggan:id,name',
            ]);

            // Filter by stars
            if ($request->filled('stars')) {
                $query->where('stars', (int) $request->query('stars'));
            }

            // Filter by hidden
            if ($request->filled('hidden')) {
                $query->where('is_hidden', (int) $request->query('hidden'));
            }

            $ratings = $query->latest()->get();

            // Summary
            $all = Rating::where('is_hidden', 0)->get();
            $total     = $all->count();
            $avg       = $total > 0 ? round($all->avg('stars'), 1) : 0;
            $highCount = $all->where('stars', '>=', 4)->count();
            $lowCount  = $all->where('stars', '<=', 2)->count();

            return response()->json([
                'success' => true,
                'summary' => [
                    'total'       => $total,
                    'average'     => $avg,
                    'high_count'  => $highCount,
                    'low_count'   => $lowCount,
                ],
                'data' => $ratings,
            ], 200);

        } catch (\Exception $e) {
            Log::error('RatingController@adminIndex: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat rating.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * ADMIN — DETAIL RATING
     * GET /admin/ratings/{id}
     * =========================================================
     */
    public function show($id)
    {
        try {
            $rating = Rating::with([
                'job',
                'mitra:id,name,email',
                'pelanggan:id,name,email',
                'hider:id,name',
            ])->find($id);

            if (!$rating) {
                return response()->json([
                    'success' => false,
                    'message' => 'Rating tidak ditemukan.',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data'    => $rating,
            ], 200);

        } catch (\Exception $e) {
            Log::error('RatingController@show: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat detail rating.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * ADMIN — HAPUS RATING (hard delete)
     * DELETE /admin/ratings/{id}
     * =========================================================
     */
    public function destroy($id)
    {
        try {
            $rating = Rating::find($id);

            if (!$rating) {
                return response()->json([
                    'success' => false,
                    'message' => 'Rating tidak ditemukan.',
                ], 404);
            }

            $mitraId = $rating->mitra_id;
            $rating->delete();

            // Update aggregate rating mitra
            $this->recalculateMitraRating($mitraId);

            return response()->json([
                'success' => true,
                'message' => 'Rating berhasil dihapus.',
            ], 200);

        } catch (\Exception $e) {
            Log::error('RatingController@destroy: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus rating.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * ADMIN — SEMBUNYIKAN RATING (soft hide)
     * PUT /admin/ratings/{id}/hide
     * =========================================================
     */
    public function hide(Request $request, $id)
    {
        try {
            $rating = Rating::find($id);

            if (!$rating) {
                return response()->json([
                    'success' => false,
                    'message' => 'Rating tidak ditemukan.',
                ], 404);
            }

            $request->validate([
                'reason' => 'nullable|string|max:500',
            ]);

            $rating->update([
                'is_hidden'     => 1,
                'hidden_by'     => auth()->id(),
                'hidden_at'     => now(),
                'hidden_reason' => $request->reason,
            ]);

            $this->recalculateMitraRating($rating->mitra_id);

            return response()->json([
                'success' => true,
                'message' => 'Rating berhasil disembunyikan.',
                'data'    => $rating->fresh(),
            ], 200);

        } catch (\Exception $e) {
            Log::error('RatingController@hide: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal menyembunyikan rating.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * ADMIN — TAMPILKAN KEMBALI RATING
     * PUT /admin/ratings/{id}/unhide
     * =========================================================
     */
    public function unhide($id)
    {
        try {
            $rating = Rating::find($id);

            if (!$rating) {
                return response()->json([
                    'success' => false,
                    'message' => 'Rating tidak ditemukan.',
                ], 404);
            }

            $rating->update([
                'is_hidden'     => 0,
                'hidden_by'     => null,
                'hidden_at'     => null,
                'hidden_reason' => null,
            ]);

            $this->recalculateMitraRating($rating->mitra_id);

            return response()->json([
                'success' => true,
                'message' => 'Rating berhasil ditampilkan kembali.',
                'data'    => $rating->fresh(),
            ], 200);

        } catch (\Exception $e) {
            Log::error('RatingController@unhide: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal menampilkan rating.',
            ], 500);
        }
    }

        /**
     * =========================================================
     * PELANGGAN — BERI RATING
     * POST /pelanggan/ratings
     * =========================================================
     * Body:
     *  - job_id   : int (required)
     *  - stars    : int 1-5 (required)
     *  - comment  : string (nullable)
     */
    // public function storeFromPelanggan(Request $request)
    // {
    //     try {
    //         $request->validate([
    //             'job_id'  => 'required|integer|exists:jobs,id',
    //             'stars'   => 'required|integer|min:1|max:5',
    //             'comment' => 'nullable|string|max:1000',
    //         ]);

    //         $userId = auth()->id();

    //         // Cek job milik pelanggan ini
    //         $job = \App\Models\jobs::find($request->job_id);

    //         if (!$job) {
    //             return response()->json([
    //                 'success' => false,
    //                 'message' => 'Pekerjaan tidak ditemukan.',
    //             ], 404);
    //         }

    //         if ($job->pelanggan_id !== $userId) {
    //             return response()->json([
    //                 'success' => false,
    //                 'message' => 'Anda bukan pemilik pekerjaan ini.',
    //             ], 403);
    //         }

    //         if ($job->status !== 'Selesai') {
    //             return response()->json([
    //                 'success' => false,
    //                 'message' => 'Pekerjaan belum selesai.',
    //             ], 400);
    //         }

    //         if (!$job->mitra_id) {
    //             return response()->json([
    //                 'success' => false,
    //                 'message' => 'Pekerjaan tidak memiliki mitra.',
    //             ], 400);
    //         }

    //         // Cek sudah pernah dirating
    //         $existing = Rating::where('job_id', $job->id)
    //             ->where('pelanggan_id', $userId)
    //             ->first();

    //         if ($existing) {
    //             return response()->json([
    //                 'success' => false,
    //                 'message' => 'Anda sudah memberi rating untuk pekerjaan ini.',
    //             ], 400);
    //         }

    //         $rating = Rating::create([
    //             'job_id'       => $job->id,
    //             'mitra_id'     => $job->mitra_id,
    //             'pelanggan_id' => $userId,
    //             'stars'        => $request->stars,
    //             'comment'      => $request->comment,
    //             'is_hidden'    => 0,
    //         ]);

    //         // Update aggregate rating mitra
    //         $this->recalculateMitraRating($job->mitra_id);

    //         return response()->json([
    //             'success' => true,
    //             'message' => 'Terima kasih! Rating berhasil dikirim.',
    //             'data'    => $rating,
    //         ], 201);

    //     } catch (\Illuminate\Validation\ValidationException $e) {
    //         throw $e;
    //     } catch (\Exception $e) {
    //         Log::error('RatingController@storeFromPelanggan: ' . $e->getMessage());
    //         return response()->json([
    //             'success' => false,
    //             'message' => 'Gagal mengirim rating: ' . $e->getMessage(),
    //         ], 500);
    //     }
    // }

    public function storeFromPelanggan(Request $request)
    {
        try {
            $request->validate([
                'job_id'  => 'required|integer|exists:jobs,id',
                'stars'   => 'required|integer|min:1|max:5',
                'comment' => 'nullable|string|max:1000',
            ]);

            $userId = auth()->id();

            $job = \App\Models\jobs::find($request->job_id);

            if (!$job) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pekerjaan tidak ditemukan.',
                ], 404);
            }

            if ($job->pelanggan_id !== $userId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda bukan pemilik pekerjaan ini.',
                ], 403);
            }

            if ($job->status !== 'Selesai') {
                return response()->json([
                    'success' => false,
                    'message' => 'Pekerjaan belum selesai.',
                ], 400);
            }

            if (!$job->mitra_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pekerjaan tidak memiliki mitra.',
                ], 400);
            }

            // ============================================================
            // 🆕 WAJIB: pelanggan harus sudah upload bukti transfer
            // ============================================================
            $payment = \App\Models\Payment::where('job_id', $job->id)->first();

            if (!$payment || empty($payment->customer_proof_url)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda harus mengirim bukti pembayaran ke admin '
                            . 'terlebih dahulu sebelum memberi rating.',
                ], 400);
            }

            // Cek sudah pernah dirating
            $existing = Rating::where('job_id', $job->id)
                ->where('pelanggan_id', $userId)
                ->first();

            if ($existing) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda sudah memberi rating untuk pekerjaan ini.',
                ], 400);
            }

            $rating = Rating::create([
                'job_id'       => $job->id,
                'mitra_id'     => $job->mitra_id,
                'pelanggan_id' => $userId,
                'stars'        => $request->stars,
                'comment'      => $request->comment,
                'is_hidden'    => 0,
            ]);

            $this->recalculateMitraRating($job->mitra_id);

            return response()->json([
                'success' => true,
                'message' => 'Terima kasih! Rating berhasil dikirim.',
                'data'    => $rating,
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('RatingController@storeFromPelanggan: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengirim rating: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * =========================================================
     * PELANGGAN — CEK RATING JOB
     * GET /pelanggan/ratings/job/{jobId}
     * =========================================================
     * Cek apakah pelanggan sudah memberi rating untuk job ini.
     */
    public function checkJobRating($jobId)
    {
        try {
            $userId = auth()->id();

            $rating = Rating::where('job_id', $jobId)
                ->where('pelanggan_id', $userId)
                ->first();

            return response()->json([
                'success' => true,
                'has_rating' => $rating != null,
                'data'    => $rating,
            ], 200);

        } catch (\Exception $e) {
            Log::error('RatingController@checkJobRating: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal memeriksa rating.',
            ], 500);
        }
    }

    /**
     * =========================================================
     * HITUNG ULANG RATING MITRA (setelah delete/hide)
     * =========================================================
     */
    private function recalculateMitraRating($mitraId)
    {
        try {
            $visible = Rating::where('mitra_id', $mitraId)
                ->where('is_hidden', 0);

            $count = $visible->count();
            $avg   = $count > 0 ? round($visible->avg('stars'), 1) : 0.0;

            mitra_profiles::where('user_id', $mitraId)->update([
                'rating' => $avg,
            ]);

        } catch (\Exception $e) {
            Log::warning('Recalculate mitra rating failed: ' . $e->getMessage());
        }
    }
}