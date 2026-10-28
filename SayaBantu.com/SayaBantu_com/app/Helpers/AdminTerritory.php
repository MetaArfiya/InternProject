<?php

namespace App\Helpers;

use App\Models\jobs;
use App\Models\users;
use Illuminate\Database\Eloquent\Builder;

class AdminTerritory
{
    public static function area(?users $admin = null): string
    {
        $admin ??= auth()->user();
        return RegionFormat::normalize($admin?->admin_region);
    }

    public static function constrainJobs(Builder $query, string $column = 'location'): Builder
    {
        $area = self::area();
        if ($area === '') return $query->whereRaw('1 = 0');
        $patterns = array_map(fn ($variant) => '%' . addcslashes($variant, '%_\\') . '%', RegionFormat::variants($area));
        return $query->where(function ($jobs) use ($area, $patterns, $column) {
            $jobs->whereRaw('LOWER(TRIM(region)) = ?', [RegionFormat::key($area)])
                ->orWhere(function ($legacy) use ($patterns, $column) {
                    $legacy->whereNull('region')->where(function ($locations) use ($patterns, $column) {
                        foreach ($patterns as $pattern) $locations->orWhere($column, 'like', $pattern);
                    });
                });
        });
    }

    public static function constrainMitraProfiles(Builder $query): Builder
    {
        $area = self::area();
        if ($area === '') return $query->whereRaw('1 = 0');
        $patterns = array_map(fn ($variant) => '%' . addcslashes($variant, '%_\\') . '%', RegionFormat::variants($area));
        return $query->where(function ($profiles) use ($area, $patterns) {
            $profiles->whereRaw('LOWER(TRIM(city)) = ?', [RegionFormat::key($area)])
                ->orWhere(function ($legacy) use ($patterns) {
                    foreach ($patterns as $pattern) $legacy->orWhere('city', 'like', $pattern);
                });
        });
    }

    public static function constrainAddress(Builder $query, string $column = 'address'): Builder
    {
        $area = self::area();
        if ($area === '') return $query->whereRaw('1 = 0');
        $patterns = array_map(fn ($variant) => '%' . addcslashes($variant, '%_\\') . '%', RegionFormat::variants($area));
        return $query->where(function ($addresses) use ($patterns, $column) {
            foreach ($patterns as $pattern) $addresses->orWhere($column, 'like', $pattern);
        });
    }

    public static function addressMatches(?string $address, ?users $admin = null): bool
    {
        foreach (RegionFormat::variants(self::area($admin)) as $variant) {
            if ($variant !== '' && stripos((string) $address, $variant) !== false) return true;
        }
        return false;
    }

    public static function allowsJob(?jobs $job): bool
    {
        $area = self::area();
        if ($job === null || $area === '') return false;
        if (!empty($job->region)) return RegionFormat::key($job->region) === RegionFormat::key($area);
        foreach (RegionFormat::variants($area) as $variant) {
            if (stripos((string) $job->location, $variant) !== false) return true;
        }
        return false;
    }

    public static function allowsMitraProfile($profile): bool
    {
        $area = self::area();
        if ($profile === null || $area === '') return false;
        if (RegionFormat::key($profile->city) === RegionFormat::key($area)) return true;
        foreach (RegionFormat::variants($area) as $variant) {
            if (stripos((string) $profile->city, $variant) !== false) return true;
        }
        return false;
    }
}
