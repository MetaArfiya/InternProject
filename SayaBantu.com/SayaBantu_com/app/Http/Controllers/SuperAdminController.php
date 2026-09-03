<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\users;
use App\Models\jobs;
use App\Models\mitra_profiles;
use App\Models\system_setting;
use App\Models\SuperAdminActivity;
use Illuminate\Support\Facades\Hash;
use App\Helpers\ActivityLogger;

class SuperAdminController extends Controller
{
    /**
     * 1. MENGELOLA AKUN: Membuat Akun Admin Baru
     * Hanya Super Admin yang bisa mendaftarkan orang lain menjadi Admin biasa (role_id = 2)
     */
    public function createAdmin(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',

            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                'unique:users,email',
            ],

            'password' => 'required|string|min:6',

            'phone' => 'nullable|string|max:20',
        ]);

        $admin = users::create([
            'role_id' => 2,
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'is_active' => true,
            'last_login_at' => null,
        ]);

        ActivityLogger::log(
            $request->user()?->id,
            'Menambahkan admin baru',
            'Menambahkan akun admin ' . $admin->name,
            'person_add',
            'Admin'
        );

        // =========================================================
        // CATAT AKTIVITAS SUPER ADMIN
        // =========================================================

        if ($request->user()) {
            SuperAdminActivity::create([
                'super_admin_id' => $request->user()->id,

                'title' => 'Menambahkan admin baru',

                'detail' =>
                    'Menambahkan akun admin ' . $admin->name,

                'icon' => 'person_add',

                'type' => 'Admin',
            ]);
        }

        return response()->json([
            'success' => true,

            'message' =>
                'Akun Admin baru berhasil dibuat oleh Super Admin!',

            'data' => [
                'id' => $admin->id,
                'name' => $admin->name,
                'email' => $admin->email,
                'phone' => $admin->phone,
                'is_active' => $admin->is_active,
                'last_login_at' => $admin->last_login_at,
            ],
        ], 201);
    }

    // 2. MENGELOLA SETTINGAN SISTEM: Mengambil Data Konfigurasi Aplikasi
    public function getSystemSettings()
    {
        try {

            $setting = system_setting::first();

            // Jika belum ada, buat default
            if (!$setting) {

                $setting = system_setting::create([
                    'updated_by' => null,
                    'points_on_completion' => 10,
                    'points_on_cancellation' => 5,
                    'points_bonus_rating' => 3,
                    'platform_commission_percent' => 15,
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Pengaturan sistem berhasil diambil.',
                'data' => $setting,
            ], 200);

        } catch (\Exception $e) {

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil pengaturan sistem.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }


    /**
     * 2. SETTING SISTEM: Mengatur Kebijakan Poin / Aturan Aplikasi
     */
    public function updateSystemSettings(Request $request)
    {
        try {

            // ======================================================
            // VALIDASI
            // ======================================================

            $validated = $request->validate([
                'points_on_completion' => [
                    'required',
                    'integer',
                    'min:0',
                ],

                'points_on_cancellation' => [
                    'required',
                    'integer',
                    'min:0',
                ],

                'points_bonus_rating' => [
                    'required',
                    'integer',
                    'min:0',
                ],

                'platform_commission_percent' => [
                    'required',
                    'numeric',
                    'min:0',
                    'max:100',
                ],
            ]);


            // ======================================================
            // AMBIL SETTING
            // ======================================================

            $setting = system_setting::first();


            // ======================================================
            // JIKA BELUM ADA, BUAT BARU
            // ======================================================

            if (!$setting) {

                $setting = new system_setting();

                $setting->points_on_completion =
                    $validated['points_on_completion'];

                $setting->points_on_cancellation =
                    $validated['points_on_cancellation'];

                $setting->points_bonus_rating =
                    $validated['points_bonus_rating'];

                $setting->platform_commission_percent =
                    $validated['platform_commission_percent'];

            } else {

                // ==================================================
                // UPDATE DATA
                // ==================================================

                $setting->points_on_completion =
                    $validated['points_on_completion'];

                $setting->points_on_cancellation =
                    $validated['points_on_cancellation'];

                $setting->points_bonus_rating =
                    $validated['points_bonus_rating'];

                $setting->platform_commission_percent =
                    $validated['platform_commission_percent'];
            }


            // ======================================================
            // USER YANG MELAKUKAN UPDATE
            // ======================================================

            if ($request->user()) {
                $setting->updated_by =
                    $request->user()->id;
            }


            // ======================================================
            // SIMPAN
            // ======================================================

            $setting->save();
            if ($request->user()) {
                SuperAdminActivity::create([
                    'super_admin_id' => $request->user()->id,

                    'title' => 'Mengubah pengaturan sistem',

                    'detail' =>
                        'Pengaturan sistem berhasil diperbarui.',

                    'icon' => 'settings',

                    'type' => 'Sistem',
                ]);
            }

            ActivityLogger::log(
                $request->user()?->id,
                'Mengubah pengaturan sistem',
                'Pengaturan sistem berhasil diperbarui.',
                'settings',
                'Sistem'
            );

            // ======================================================
            // RESPONSE
            // ======================================================

            return response()->json([
                'success' => true,
                'message' => 'Pengaturan sistem berhasil diperbarui.',
                'data' => $setting,
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {

            return response()->json([
                'success' => false,
                'message' => 'Data pengaturan tidak valid.',
                'errors' => $e->errors(),
            ], 422);

        } catch (\Exception $e) {

            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui pengaturan sistem.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * 3. PLATFORM ANALYTICS: Menampilkan Data Grafik & Ringkasan
     */
    public function analytics()
    {
        // ============================================================
        // PERIODE ANALYTICS: 7 HARI TERAKHIR
        // ============================================================

        $endDate = now()->endOfDay();
        $startDate = now()->subDays(6)->startOfDay();

        // ============================================================
        // 1. JOB SELESAI
        // ============================================================

        $jobsSelesai = jobs::where('status', 'Selesai')
            ->whereBetween('updated_at', [$startDate, $endDate])
            ->get();

        $jumlahJobSelesai = $jobsSelesai->count();

        // ============================================================
        // 2. TOTAL TRANSAKSI
        // ============================================================
        // Menggunakan final_price dari job yang selesai.
        //
        // Jika final_price null, gunakan initial_budget.

        $totalTransaksi = $jobsSelesai->sum(function ($job) {
            return $job->final_price ?? $job->initial_budget ?? 0;
        });

        // ============================================================
        // 3. PENGGUNA BARU
        // ============================================================

        $penggunaBaru = users::whereIn('role_id', [3, 4])
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        $pelangganBaru = users::where('role_id', 4)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        $mitraBaru = users::where('role_id', 3)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        // ============================================================
        // 4. TOTAL MITRA AKTIF
        // ============================================================
        // Untuk saat ini "aktif" = sudah diverifikasi.

        $mitraAktif = mitra_profiles::where('is_verified', 1)->count();

        // ============================================================
        // 5. MITRA MENUNGGU VERIFIKASI
        // ============================================================

        $mitraMenunggu = mitra_profiles::where('is_verified', 0)->count();

        // ============================================================
        // 6. DATA 7 HARI
        // ============================================================

        $jobSelesaiPerHari = [];
        $pendapatanPerHari = [];
        $pertumbuhanPengguna = [];

        for ($i = 0; $i < 7; $i++) {

            $tanggal = now()->subDays(6 - $i);

            $awalHari = $tanggal->copy()->startOfDay();
            $akhirHari = $tanggal->copy()->endOfDay();

            // Nama hari Indonesia
            $namaHari = [
                0 => 'Min',
                1 => 'Sen',
                2 => 'Sel',
                3 => 'Rab',
                4 => 'Kam',
                5 => 'Jum',
                6 => 'Sab',
            ];

            $hari = $namaHari[$tanggal->dayOfWeek];

            // --------------------------------------------------------
            // JOB SELESAI PER HARI
            // --------------------------------------------------------

            $jobsHariIni = jobs::where('status', 'Selesai')
                ->whereBetween('updated_at', [$awalHari, $akhirHari])
                ->get();

            $jobSelesaiPerHari[$hari] = $jobsHariIni->count();

            // --------------------------------------------------------
            // PENDAPATAN / TRANSAKSI PER HARI
            // --------------------------------------------------------

            $pendapatanPerHari[$hari] = $jobsHariIni->sum(function ($job) {
                return $job->final_price ?? $job->initial_budget ?? 0;
            });

            // --------------------------------------------------------
            // PENGGUNA BARU PER HARI
            // --------------------------------------------------------

            $userBaruHariIni = users::whereIn('role_id', [3, 4])
                ->whereBetween('created_at', [$awalHari, $akhirHari])
                ->count();

            $pertumbuhanPengguna[$hari] = $userBaruHariIni;
        }

        // ============================================================
        // 7. RESPONSE
        // ============================================================

        return response()->json([
            'success' => true,

            'period' => [
                'start' => $startDate->format('Y-m-d'),
                'end'   => $endDate->format('Y-m-d'),
            ],

            'summary' => [
                'total_transaksi' => $totalTransaksi,
                'job_selesai' => $jumlahJobSelesai,
                'pengguna_baru' => $penggunaBaru,
                'pelanggan_baru' => $pelangganBaru,
                'mitra_baru' => $mitraBaru,
                'mitra_aktif' => $mitraAktif,
                'mitra_menunggu' => $mitraMenunggu,
            ],

            'charts' => [
                'job_selesai_per_hari' => $jobSelesaiPerHari,
                'pendapatan_harian' => $pendapatanPerHari,
                'pertumbuhan_pengguna' => $pertumbuhanPengguna,
            ],
        ], 200);
    }

    /**
     * 4. MENAMPILKAN DAFTAR AKUN ADMIN (READ)
     */
    public function getAdmins()
    {
        $admins = users::where('role_id', 2)
            ->latest()
            ->get([
                'id',
                'name',
                'email',
                'phone',
                'is_active',
                'last_login_at',
                'created_at',
            ]);

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil daftar akun admin.',
            'data' => $admins,
        ], 200);
    }

    /**
     * 5. MENGUBAH DATA ADMIN (UPDATE)
     * Untuk aksi tombol "Edit" di tabel
     */
    public function updateAdmin(Request $request, $id)
    {
        $admin = users::where('role_id', 2)->find($id);

        if (!$admin) {
            return response()->json([
                'success' => false,
                'message' => 'Akun Admin tidak ditemukan!',
            ], 404);
        }

        $request->validate([
            'name' => 'required|string|max:255',

            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                'unique:users,email,' . $id,
            ],

            'phone' => 'nullable|string|max:20',

            'is_active' => 'required|boolean',
        ]);

        // Simpan data lama sebelum update
        $oldName = $admin->name;
        $oldStatus = $admin->is_active;

        // Update data
        $admin->update([
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
            'is_active' => $request->is_active,
        ]);

        // ============================================================
        // TENTUKAN JENIS AKTIVITAS
        // ============================================================

        if ((bool) $oldStatus !== (bool) $request->is_active) {

            if ($request->is_active) {
                $title = 'Mengaktifkan admin';
                $detail = 'Mengaktifkan akun admin ' . $admin->name;
                $icon = 'check_circle';
            } else {
                $title = 'Menonaktifkan admin';
                $detail = 'Menonaktifkan akun admin ' . $admin->name;
                $icon = 'block';
            }

        } else {

            $title = 'Mengubah data admin';
            $detail = 'Memperbarui informasi akun ' . $admin->name;
            $icon = 'edit';
        }

        // ============================================================
        // CATAT KE ACTIVITY LOGGER
        // ============================================================

        ActivityLogger::log(
            $request->user()?->id,
            $title,
            $detail,
            $icon,
            'Admin'
        );

        // ============================================================
        // CATAT KE SUPER ADMIN ACTIVITY
        // ============================================================

        if ($request->user()) {
            SuperAdminActivity::create([
                'super_admin_id' => $request->user()->id,
                'title' => $title,
                'detail' => $detail,
                'icon' => $icon,
                'type' => 'Admin',
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Data Admin berhasil diperbarui!',

            'data' => [
                'id' => $admin->id,
                'name' => $admin->name,
                'email' => $admin->email,
                'phone' => $admin->phone,
                'is_active' => $admin->is_active,
                'last_login_at' => $admin->last_login_at,
            ],
        ], 200);
    }

    /**
     * 6. MENGHAPUS AKUN ADMIN (DELETE)
     * Untuk aksi tombol "Hapus" (Merah) di tabel
     */
    public function deleteAdmin($id)
    {
        $admin = users::where('role_id', 2)->find($id);

        if (!$admin) {
            return response()->json([
                'success' => false,
                'message' => 'Akun Admin tidak ditemukan!'
            ], 404);
        }

        // Simpan nama sebelum data dihapus
        $adminName = $admin->name;

        $admin->delete();

        ActivityLogger::log(
            request()->user()?->id,
            'Menghapus admin',
            'Menghapus akun admin ' . $adminName,
            'delete',
            'Admin'
        );

        // =========================================================
        // CATAT AKTIVITAS SUPER ADMIN
        // =========================================================

        if (request()->user()) {
            SuperAdminActivity::create([
                'super_admin_id' => request()->user()->id,

                'title' => 'Menghapus admin',

                'detail' =>
                    'Menghapus akun admin ' . $adminName,

                'icon' => 'delete',

                'type' => 'Admin',
            ]);
        }

        return response()->json([
            'success' => true,
            'message' =>
                'Akun Admin berhasil dihapus dari sistem secara permanen.'
        ], 200);
    }
}