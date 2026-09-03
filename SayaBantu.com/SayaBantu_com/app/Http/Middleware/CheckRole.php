<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    /**
     * Menyeleksi apakah user yang login punya role yang diizinkan
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        // 1. Cek apakah user sudah login
        if (!auth()->check()) {
            return response()->json(['message' => 'Silakan login terlebih dahulu!'], 401);
        }

        $user = auth()->user();

        $user->load('role');

        // 2. Ambil nama role dengan aman (mencegah error jika relasi null)
        $userRole = $user->role ? $user->role->role_name : null;

        if (!$userRole) {
            return response()->json([
                'message' => 'Akses ditolak! Akun Anda tidak memiliki role yang valid.'
            ], 403);
        }

        // 3. Transformasi semua role ke huruf kecil (Case-Insensitive Check)
        $userRoleLower = strtolower($userRole);
        $allowedRolesLower = array_map('strtolower', $roles);

        // 4. Cek apakah role user ada di dalam daftar role yang diizinkan
        if (!in_array($userRoleLower, $allowedRolesLower)) {
            return response()->json([
                'message' => "Akses ditolak! User '{$user->email}' memiliki role '{$userRole}', tetapi route ini butuh: " . implode(', ', $roles)
            ], 403);
        }

        return $next($request);
    }
}