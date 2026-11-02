<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\users;
use App\Models\mitra_profiles;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use App\Helpers\ActivityLogger;

class AuthController extends Controller
{
    // =========================================================
    // REGISTER
    // =========================================================

    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'password' => 'required|string|min:6',
            'role_id' => 'required|integer|in:3,4',
            'city_id' => 'required|integer|exists:cities,id',
        ], [
            'name.required' => 'Nama wajib diisi.',
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'email.unique' => 'Email sudah terdaftar.',
            'password.required' => 'Password wajib diisi.',
            'password.min' => 'Password minimal 6 karakter.',
            'role_id.required' => 'Role wajib dipilih.',
            'role_id.in' => 'Role yang dipilih tidak valid.',
            'city_id.required' => 'Kota domisili wajib dipilih.',
            'city_id.integer' => 'Kota domisili tidak valid.',
            'city_id.exists' => 'Kota yang dipilih tidak tersedia.',
        ]);

        $user = users::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role_id' => $validated['role_id'],
            'city_id' => $validated['city_id'],
        ]);

        // Jika mendaftar sebagai Mitra
        if ((int) $user->role_id === 3) {
            mitra_profiles::create([
                'user_id' => $user->id,
                'is_verified' => 0,
                'point' => 0,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil! Silakan lakukan login.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role_id' => $user->role_id,
                'city_id' => $user->city_id,
            ],
        ], 201);
    }

    // =========================================================
    // LOGIN
    // =========================================================

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if (!Auth::attempt([
            'email' => $request->email,
            'password' => $request->password,
        ])) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah!',
            ], 401);
        }

        $user = users::with('role')
            ->where('email', $request->email)
            ->first();

        if (!$user) {
            Auth::logout();
            return response()->json([
                'success' => false,
                'message' => 'Data pengguna tidak ditemukan.',
            ], 404);
        }

        if (!$user->is_active) {
            Auth::logout();
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda sedang dinonaktifkan.',
            ], 403);
        }

        $roleName = $user->role?->role_name;

        if (!$roleName) {
            Auth::logout();
            return response()->json([
                'success' => false,
                'message' => 'Role pengguna tidak ditemukan.',
            ], 403);
        }

        $user->update([
            'last_login_at' => now(),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        try {
            ActivityLogger::log(
                $user->id,
                'Login ke sistem',
                $roleName . ' berhasil login ke sistem.',
                'login',
                'Login'
            );
        } catch (\Exception $e) {
            Log::error('Gagal menyimpan activity login: ' . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil! Selamat datang, ' . $user->name,
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user_role' => $roleName,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'address' => $user->address,
                'photo_url' => $user->photo_profile,
                'is_active' => $user->is_active,
                'last_login_at' => $user->last_login_at,
                'city_id' => $user->city_id,
            ]
        ]);
    }

    // =========================================================
    // UPDATE NOTIFICATION SETTING
    // =========================================================

    public function updateNotificationSetting(Request $request)
    {
        $request->validate([
            'is_notification_enabled' => 'required|boolean',
        ]);

        $user = $request->user();

        $user->update([
            'is_notification_enabled' => $request->is_notification_enabled,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengaturan notifikasi berhasil diperbarui.',
            'data' => [
                'name' => $user->name,
                'is_notification_enabled' => $user->is_notification_enabled,
            ]
        ], 200);
    }

    // =========================================================
    // UBAH PASSWORD
    // =========================================================

    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6|confirmed',
        ]);

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password lama Anda tidak sesuai.',
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah!',
        ], 200);
    }

    // =========================================================
    // DATA USER YANG SEDANG LOGIN
    // =========================================================

    public function me(Request $request)
    {
        $user = $request->user();

        $user->load(['mitraProfile', 'city']);

        $mitraProfileData = null;

        if ($user->mitraProfile) {
            $mitraProfileData = [
                'point' => $user->mitraProfile->point ?? 0,
                'is_verified' => $user->mitraProfile->is_verified ?? 0,
            ];
        }

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone ?? "",
                'address' => $user->address ?? "",
                'is_notification_enabled' => $user->is_notification_enabled ?? 1,
                'photo_url' => $user->photo_profile ?? null,
                'mitra_profile' => $mitraProfileData,

                // DATA KOTA
                'city_id' => $user->city_id,
                'city' => $user->city ? [
                    'id' => $user->city->id,
                    'name' => $user->city->name,
                ] : null,

                'has_pin' => !empty($user->pin),

                // DATA BANK
                'bank_name' => $user->bank_name ?? "",
                'bank_account_number' => $user->bank_account_number ?? "",
                'bank_account_name' => $user->bank_account_name ?? "",
            ]
        ], 200);
    }

    // =========================================================
    // UPDATE PROFIL
    // =========================================================


    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                'unique:users,email,' . $user->id,
            ],
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string',

            // VALIDASI KOTA DOMISILI
            'city_id' => 'required|integer|exists:cities,id',

            // VALIDASI BANK
            'bank_name' => 'nullable|string|max:100',
            'bank_account_number' => 'nullable|string|max:50',
            'bank_account_name' => 'nullable|string|max:100',
        ], [
            'city_id.required' => 'Kota domisili wajib dipilih.',
            'city_id.integer' => 'Kota domisili tidak valid.',
            'city_id.exists' => 'Kota yang dipilih tidak tersedia.',
        ]);

        $user->update([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'] ?? null,
            'address' => $validated['address'] ?? null,

            // SIMPAN KOTA DOMISILI
            'city_id' => $validated['city_id'],

            // UPDATE BANK
            'bank_name' => $validated['bank_name'] ?? null,
            'bank_account_number' => $validated['bank_account_number'] ?? null,
            'bank_account_name' => $validated['bank_account_name'] ?? null,
        ]);

        // Ambil ulang data terbaru beserta relasi kota
        $user->refresh();
        $user->load('city');

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'address' => $user->address,

                // DATA KOTA
                'city_id' => $user->city_id,
                'city' => $user->city ? [
                    'id' => $user->city->id,
                    'name' => $user->city->name,
                ] : null,

                // DATA BANK
                'bank_name' => $user->bank_name,
                'bank_account_number' => $user->bank_account_number,
                'bank_account_name' => $user->bank_account_name,

                'photo_url' => $user->photo_profile,
            ]
        ], 200);
    }


    // =========================================================
    // UPLOAD FOTO PROFIL
    // =========================================================

    public function uploadProfilePhoto(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User tidak ditemukan.',
                ], 401);
            }

            $request->validate([
                'photo_profile' => [
                    'required',
                    'image',
                    'mimes:jpg,jpeg,png,webp',
                    'max:5120',
                ],
            ], [
                'photo_profile.required' => 'Foto profil wajib dipilih.',
                'photo_profile.image' => 'File yang diunggah harus berupa gambar.',
                'photo_profile.mimes' => 'Format foto harus JPG, JPEG, PNG, atau WEBP.',
                'photo_profile.max' => 'Ukuran foto maksimal 5 MB.',
            ]);

            $file = $request->file('photo_profile');

            if (!$file || !$file->isValid()) {
                return response()->json([
                    'success' => false,
                    'message' => 'File foto tidak valid.',
                ], 422);
            }

            if (!empty($user->photo_profile) && Storage::disk('public')->exists($user->photo_profile)) {
                Storage::disk('public')->delete($user->photo_profile);
            }

            $path = $file->store('profile_photos', 'public');

            if (!$path) {
                return response()->json([
                    'success' => false,
                    'message' => 'Foto gagal disimpan ke storage.',
                ], 500);
            }

            $user->photo_profile = $path;
            $user->save();

            return response()->json([
                'success' => true,
                'message' => 'Foto profil berhasil diupload.',
                'photo_url' => $user->photo_profile,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'address' => $user->address,
                    'photo_url' => $user->photo_profile,
                ]
            ], 200);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi foto gagal.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Gagal upload foto profil: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Gagal upload foto profil.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // =========================================================
    // ATUR PIN KEAMANAN
    // =========================================================

    public function setPin(Request $request)
    {
        $request->validate([
            'pin' => 'required|digits:6',
        ]);

        $user = $request->user();

        if (!empty($user->pin)) {
            $request->validate([
                'old_pin' => 'required|digits:6',
            ]);

            if (!Hash::check($request->old_pin, $user->pin)) {
                return response()->json([
                    'success' => false,
                    'message' => 'PIN lama Anda salah.',
                ], 400);
            }
        }

        $user->update([
            'pin' => Hash::make($request->pin),
        ]);

        ActivityLogger::log(
            $user->id,
            'Mengatur PIN keamanan',
            'User mengatur/mengubah PIN 6 digit.',
            'lock',
            'User'
        );

        return response()->json([
            'success' => true,
            'message' => 'PIN berhasil diatur.',
        ], 200);
    }

    // =========================================================
    // RESET PASSWORD
    // =========================================================

    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email',
            'password' => 'required|min:6|confirmed',
        ]);

        $user = users::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Email tidak terdaftar di sistem.',
            ], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah. Silakan login kembali.',
        ], 200);
    }
}
