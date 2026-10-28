<?php

namespace App\Helpers;

class RegionFormat
{
    public static function normalize(?string $region): string
    {
        $parts = array_map(static function ($part) {
            return preg_replace('/\s+/u', ' ', trim($part));
        }, explode(',', (string) $region));

        if (isset($parts[0])) {
            $parts[0] = preg_replace('/^(?:kota(?:\s+administrasi)?|kabupaten|kab\.)\s+/iu', '', $parts[0]);
        }

        return implode(', ', array_values(array_filter($parts, static fn ($part) => $part !== '')));
    }

    public static function key(?string $region): string
    {
        return mb_strtolower(self::normalize($region));
    }

    public static function isCanonical(?string $region): bool
    {
        $parts = explode(',', self::normalize($region));
        return count($parts) === 2 && $parts[0] !== '' && $parts[1] !== '';
    }

    public static function variants(?string $region): array
    {
        $parts = explode(', ', self::normalize($region));
        if (count($parts) !== 2) return [self::normalize($region)];
        [$locality, $province] = $parts;
        return array_unique([
            "$locality, $province",
            "Kota $locality, $province",
            "Kabupaten $locality, $province",
            "Kab. $locality, $province",
            $locality,
            "Kota $locality",
            "Kabupaten $locality",
            "Kab. $locality",
        ]);
    }
}
