<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\JsonResponse;

trait EnforcesAdminCity
{
    protected function adminCityId($admin): ?int
    {
        if (!$admin || (int) $admin->role_id !== 2 || !$admin->city_id) {
            return null;
        }

        return (int) $admin->city_id;
    }

    protected function missingAdminCityResponse($admin): ?JsonResponse
    {
        if (!$admin) {
            return response()->json([
                'success' => false,
                'message' => 'Admin belum terautentikasi.',
            ], 401);
        }

        if ((int) $admin->role_id === 2 && !$admin->city_id) {
            return response()->json([
                'success' => false,
                'message' => 'Akun Admin Daerah belum memiliki wilayah.',
            ], 403);
        }

        return null;
    }

    protected function scopeByAdminCity($query, $admin, string $relation = 'user')
    {
        $cityId = $this->adminCityId($admin);
        if ($cityId !== null) {
            $query->whereHas($relation, fn ($user) => $user->where('city_id', $cityId));
        }

        return $query;
    }
}
