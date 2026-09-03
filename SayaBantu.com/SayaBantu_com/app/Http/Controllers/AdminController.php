<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\mitra_profiles;
use App\Models\users;
use App\Models\jobs;
use App\Helpers\ActivityLogger;

class AdminController extends Controller
{
    // =========================================================
    // MITRA BELUM DIVERIFIKASI
    // =========================================================

    public function unverifiedMitra()
    {
        // Mengambil profil mitra yang belum diverifikasi
        $mitras = mitra_profiles::with('user')
            ->where('is_verified', 0)
            ->latest()
            ->get();

        // =====================================================
        // STATISTIK
        // =====================================================

        $menungguCount = mitra_profiles::where(
            'is_verified',
            0
        )->count();

        $disetujuiHariIni = mitra_profiles::where(
            'is_verified',
            1
        )
            ->whereDate(
                'verified_at',
                today()
            )
            ->count();

        $ditolakCount = mitra_profiles::where(
            'is_verified',
            2
        )->count();

        return response()->json([
            'success' => true,

            'message' =>
                'Daftar Mitra yang menunggu verifikasi.',

            'statistics' => [
                'menunggu' =>
                    $menungguCount,

                'disetujui_hari_ini' =>
                    $disetujuiHariIni,

                'ditolak' =>
                    $ditolakCount,
            ],

            'data' => $mitras,
        ], 200);
    }


    // =========================================================
    // VERIFIKASI / PENOLAKAN MITRA
    // =========================================================

    public function verifyMitra(
        Request $request,
        $id
    ) {
        // =====================================================
        // VALIDASI
        // =====================================================

        $request->validate([
            'action' =>
                'required|string|in:approve,reject',
        ]);

        // =====================================================
        // ADMIN YANG LOGIN
        // =====================================================

        $adminId = auth()->id();

        if (!$adminId) {
            return response()->json([
                'success' => false,

                'message' =>
                    'Admin belum terautentikasi.',
            ], 401);
        }

        // =====================================================
        // CARI PROFIL MITRA
        // =====================================================

        $mitraProfile = mitra_profiles::find($id);

        if (!$mitraProfile) {
            return response()->json([
                'success' => false,

                'message' =>
                    'Profil Mitra tidak ditemukan!',
            ], 404);
        }

        // =====================================================
        // AMBIL DATA USER MITRA
        // =====================================================

        $mitraUser = users::find($mitraProfile->user_id);

        $mitraName = $mitraUser?->name
            ?? 'Mitra';

        // =====================================================
        // APPROVE
        // =====================================================

        if ($request->action === 'approve') {

            $mitraProfile->update([
                'is_verified' => 1,

                'verified_by' => $adminId,

                'verified_at' => now(),
            ]);

            // =================================================
            // SIMPAN LOG AKTIVITAS
            // =================================================

            ActivityLogger::log(
                $adminId,

                'Mitra berhasil diverifikasi',

                'Admin memverifikasi pendaftaran mitra '
                . $mitraName
                . '.',

                'verified',

                'Admin'
            );

            $message =
                'Akun Mitra berhasil diverifikasi dan sekarang sudah aktif!';
        }

        // =====================================================
        // REJECT
        // =====================================================

        else {

            $mitraProfile->update([
                'is_verified' => 2,

                'verified_by' => $adminId,

                'verified_at' => now(),
            ]);

            // =================================================
            // SIMPAN LOG AKTIVITAS
            // =================================================

            ActivityLogger::log(
                $adminId,

                'Pendaftaran mitra ditolak',

                'Admin menolak pendaftaran mitra '
                . $mitraName
                . '.',

                'cancel',

                'Admin'
            );

            $message =
                'Pendaftaran berkas mitra telah ditolak oleh sistem.';
        }

        // =====================================================
        // RESPONSE
        // =====================================================

        return response()->json([
            'success' => true,

            'message' => $message,

            'data' => $mitraProfile,
        ], 200);
    }


    // =========================================================
    // MODERASI KONTEN
    // =========================================================

    public function contentModeration()
    {
        $jobs = jobs::with('pelanggan')
            ->latest()
            ->get();

        // =====================================================
        // JUMLAH POSTINGAN YANG DITANGGUHKAN
        // =====================================================

        $reportedCount = jobs::where(
            'status',
            'Dibatalkan'
        )->count();

        return response()->json([
            'success' => true,

            'message' =>
                'Berhasil mengambil daftar moderasi konten.',

            'reported_alert' =>
                $reportedCount
                . ' postingan telah ditangguhkan/dibatalkan oleh sistem.',

            'data' => $jobs,
        ], 200);
    }


    // =========================================================
    // MODERASI JOB
    // =========================================================

    public function moderateJob(
        Request $request,
        $id
    ) {
        // =====================================================
        // VALIDASI
        // =====================================================

        $request->validate([
            'action' =>
                'required|string|in:safe,suspend,delete',
        ]);

        // =====================================================
        // ADMIN YANG LOGIN
        // =====================================================

        $adminId = auth()->id();

        if (!$adminId) {
            return response()->json([
                'success' => false,

                'message' =>
                    'Admin belum terautentikasi.',
            ], 401);
        }

        // =====================================================
        // CARI JOB
        // =====================================================

        $job = jobs::find($id);

        if (!$job) {
            return response()->json([
                'success' => false,

                'message' =>
                    'Postingan tidak ditemukan!',
            ], 404);
        }

        // =====================================================
        // SAFE
        // =====================================================

        if ($request->action === 'safe') {

            $job->update([
                'is_verified' => 1,

                'verified_by' => $adminId,
            ]);

            // =================================================
            // SIMPAN LOG AKTIVITAS
            // =================================================

            ActivityLogger::log(
                $adminId,

                'Postingan berhasil dimoderasi',

                'Admin menyatakan postingan sebagai aman dan terverifikasi.',

                'flag',

                'Admin'
            );

            $message =
                'Postingan berhasil ditandai sebagai aman (terverifikasi).';
        }

        // =====================================================
        // SUSPEND
        // =====================================================

        elseif ($request->action === 'suspend') {

            $job->update([
                'status' => 'Dibatalkan',

                'is_verified' => 0,
            ]);

            // =================================================
            // SIMPAN LOG AKTIVITAS
            // =================================================

            ActivityLogger::log(
                $adminId,

                'Postingan berhasil ditangguhkan',

                'Admin menangguhkan postingan dari sistem.',

                'cancel',

                'Admin'
            );

            $message =
                'Postingan berhasil ditangguhkan.';
        }

        // =====================================================
        // DELETE
        // =====================================================

        else {

            $job->delete();

            // =================================================
            // SIMPAN LOG AKTIVITAS
            // =================================================

            ActivityLogger::log(
                $adminId,

                'Postingan berhasil dihapus',

                'Admin menghapus postingan secara permanen dari sistem.',

                'cancel',

                'Admin'
            );

            $message =
                'Postingan berhasil dihapus secara permanen dari sistem.';
        }

        // =====================================================
        // RESPONSE
        // =====================================================

        return response()->json([
            'success' => true,

            'message' => $message,
        ], 200);
    }
}