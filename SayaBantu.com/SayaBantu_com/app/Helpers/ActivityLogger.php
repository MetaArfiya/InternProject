<?php

namespace App\Helpers;

use App\Models\ActivityLog;

class ActivityLogger
{
    /**
     * Mencatat aktivitas user.
     */
    public static function log(
        ?int $userId,
        string $title,
        ?string $detail = null,
        ?string $icon = 'settings',
        ?string $type = 'Sistem'
    ): ActivityLog {

        return ActivityLog::create([
            'user_id' => $userId,
            'title' => $title,
            'detail' => $detail,
            'icon' => $icon,
            'type' => $type,
        ]);
    }
}