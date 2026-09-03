<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\users;
use App\Models\mitra_profiles;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use App\Helpers\ActivityLogger;

class AuthController extends Controller
{
    // =========================================================
    // REGISTER
    // =========================================================

    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'role_id'  => 'required|integer|in:3,4',
        ]);

        // =====================================================
        // BUAT USER
        // =====================================================

        $user = users::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'role_id'  => $request->role_id,
        ]);

        // =====================================================
        // JIKA MITRA
        // =====================================================

        if ($user->role_id == 3) {

            mitra_profiles::create([
                'user_id'     => $user->id,
                'is_verified' => 0,
                'point'       => 0,
            ]);
        }

        // =====================================================
        // RESPONSE
        // =====================================================

        return response()->json([
            'success' => true,

            'message' =>
                'Registrasi berhasil! Silakan lakukan login.',

            'user' => $user,

        ], 201);
    }


    // =========================================================
    // LOGIN
    // =========================================================

    public function login(Request $request)
    {
        // =====================================================
        // VALIDASI
        // =====================================================

        $request->validate([
            'email' =>
                'required|string|email',

            'password' =>
                'required|string',
        ]);


        // =====================================================
        // CEK EMAIL + PASSWORD
        // =====================================================

        if (!Auth::attempt([
            'email' => $request->email,
            'password' => $request->password,
        ])) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Email atau password salah!',

            ], 401);
        }


        // =====================================================
        // AMBIL USER + ROLE
        // =====================================================

        $user = users::with('role')
            ->where('email', $request->email)
            ->first();

        if (!$user) {

            Auth::logout();

            return response()->json([
                'success' => false,

                'message' =>
                    'Data pengguna tidak ditemukan.',

            ], 404);
        }


        // =====================================================
        // CEK STATUS AKUN
        // =====================================================

        if (!$user->is_active) {

            // Logout kembali jika akun tidak aktif
            Auth::logout();

            return response()->json([
                'success' => false,

                'message' =>
                    'Akun Anda sedang dinonaktifkan.',

            ], 403);
        }


        // =====================================================
        // AMBIL NAMA ROLE
        // =====================================================

        $roleName = $user->role?->role_name;

        if (!$roleName) {

            Auth::logout();

            return response()->json([
                'success' => false,

                'message' =>
                    'Role pengguna tidak ditemukan.',

            ], 403);
        }


        // =====================================================
        // UPDATE LOGIN TERAKHIR
        // =====================================================

        $user->update([
            'last_login_at' => now(),
        ]);


        // =====================================================
        // BUAT TOKEN
        // =====================================================

        $token =
            $user->createToken('auth_token')
                ->plainTextToken;


        // =====================================================
        // SIMPAN LOG LOGIN
        //
        // SEMUA ROLE MASUK KE SINI:
        //
        // Super Admin
        // Admin
        // Mitra
        // Pelanggan
        // =====================================================

        try {

            ActivityLogger::log(
                $user->id,

                'Login ke sistem',

                $roleName .
                    ' berhasil login ke sistem.',

                'login',

                'Login'
            );

        } catch (\Exception $e) {

            // =================================================
            // LOG AKTIVITAS GAGAL
            //
            // Jangan sampai login gagal hanya karena
            // penyimpanan activity log bermasalah.
            // =================================================

            \Log::error(
                'Gagal menyimpan activity login: '
                . $e->getMessage()
            );
        }


        // =====================================================
        // RESPONSE
        // =====================================================

        return response()->json([
            'success' => true,

            'message' =>
                'Login berhasil! Selamat datang, '
                . $user->name,

            'access_token' =>
                $token,

            'token_type' =>
                'Bearer',

            'user_role' =>
                $roleName,

            'user' => [
                'id' =>
                    $user->id,

                'name' =>
                    $user->name,

                'email' =>
                    $user->email,

                'phone' =>
                    $user->phone,

                'address' =>
                    $user->address,

                'photo_url' =>
                    $user->photo_profile,

                'is_active' =>
                    $user->is_active,

                'last_login_at' =>
                    $user->last_login_at,
            ]

        ]);
    }


    // =========================================================
    // UPDATE NOTIFICATION SETTING
    // =========================================================

    public function updateNotificationSetting(
        Request $request
    ) {
        $request->validate([
            'is_notification_enabled' =>
                'required|boolean'
        ]);

        $user = $request->user();

        $user->update([
            'is_notification_enabled' =>
                $request->is_notification_enabled
        ]);

        return response()->json([
            'success' => true,

            'message' =>
                'Pengaturan notifikasi berhasil diperbarui.',

            'data' => [
                'name' =>
                    $user->name,

                'is_notification_enabled' =>
                    $user->is_notification_enabled
            ]

        ], 200);
    }


    // =========================================================
    // UBAH PASSWORD
    // =========================================================

    public function changePassword(
        Request $request
    ) {
        $request->validate([
            'current_password' =>
                'required|string',

            'new_password' =>
                'required|string|min:6|confirmed',
        ]);

        $user = $request->user();

        // =====================================================
        // CEK PASSWORD LAMA
        // =====================================================

        if (!Hash::check(
            $request->current_password,
            $user->password
        )) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Password lama Anda tidak sesuai.'

            ], 422);
        }


        // =====================================================
        // UPDATE PASSWORD
        // =====================================================

        $user->update([
            'password' =>
                Hash::make(
                    $request->new_password
                )
        ]);


        // =====================================================
        // RESPONSE
        // =====================================================

        return response()->json([
            'success' => true,

            'message' =>
                'Password berhasil diubah!'

        ], 200);
    }


    // =========================================================
    // DATA USER YANG SEDANG LOGIN
    // =========================================================

    public function me(
        Request $request
    ) {
        $user = $request->user();

        // =====================================================
        // DATA MITRA
        // =====================================================

        $mitraProfileData = null;

        if (
            method_exists(
                $user,
                'mitraProfile'
            )
        ) {

            $user->load('mitraProfile');

            if ($user->mitraProfile) {

                $mitraProfileData = [
                    'point' =>
                        $user->mitraProfile->point
                        ?? 0,

                    'is_verified' =>
                        $user->mitraProfile->is_verified
                        ?? 0,
                ];
            }
        }


        // =====================================================
        // RESPONSE
        // =====================================================

        return response()->json([
            'success' => true,

            'user' => [
                'id' =>
                    $user->id,

                'name' =>
                    $user->name,

                'email' =>
                    $user->email,

                'phone' =>
                    $user->phone
                    ?? "",

                'address' =>
                    $user->address
                    ?? "",

                'is_notification_enabled' =>
                    $user->is_notification_enabled
                    ?? 1,

                'photo_url' =>
                    $user->photo_url
                    ?? null,

                'mitra_profile' =>
                    $mitraProfileData,
            ]

        ], 200);
    }


    // =========================================================
    // UPDATE PROFIL
    // =========================================================

    public function updateProfile(
        Request $request
    ) {
        $user = $request->user();

        // =====================================================
        // VALIDASI
        // =====================================================

        $request->validate([
            'name' =>
                'required|string|max:255',

            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                'unique:users,email,' . $user->id,
            ],

            'phone' =>
                'nullable|string|max:20',

            'address' =>
                'nullable|string',
        ]);


        // =====================================================
        // UPDATE
        // =====================================================

        $user->update([
            'name' =>
                $request->name,

            'email' =>
                $request->email,

            'phone' =>
                $request->phone,

            'address' =>
                $request->address,
        ]);


        // =====================================================
        // RESPONSE
        // =====================================================

        return response()->json([
            'success' => true,

            'message' =>
                'Profil berhasil diperbarui.',

            'user' =>
                $user

        ], 200);
    }


    // =========================================================
    // RESET PASSWORD
    // =========================================================

    public function resetPassword(
        Request $request
    ) {
        $request->validate([
            'email' =>
                'required|email|exists:users,email',

            'password' =>
                'required|min:6|confirmed',
        ]);

        // =====================================================
        // CARI USER
        // =====================================================

        $user = users::where(
            'email',
            $request->email
        )->first();

        if (!$user) {

            return response()->json([
                'success' => false,

                'message' =>
                    'Email tidak terdaftar di sistem.'

            ], 404);
        }


        // =====================================================
        // UPDATE PASSWORD
        // =====================================================

        $user->password =
            Hash::make(
                $request->password
            );

        $user->save();


        // =====================================================
        // RESPONSE
        // =====================================================

        return response()->json([
            'success' => true,

            'message' =>
                'Password berhasil diubah. Silakan login kembali.'

        ], 200);
    }
}