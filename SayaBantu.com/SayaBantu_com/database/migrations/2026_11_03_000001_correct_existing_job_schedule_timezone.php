<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // These timestamp values were persisted as UTC wall-clock values,
        // while the application interprets timestamp columns as Asia/Jakarta.
        // Move existing schedule values forward so their WIB time is preserved.
        DB::table('jobs')
            ->whereNotNull('preferred_start_at')
            ->update([
                'preferred_start_at' => DB::raw(
                    'DATE_ADD(preferred_start_at, INTERVAL 7 HOUR)'
                ),
            ]);

        DB::table('jobs')
            ->whereNotNull('scheduled_start_at')
            ->update([
                'scheduled_start_at' => DB::raw(
                    'DATE_ADD(scheduled_start_at, INTERVAL 7 HOUR)'
                ),
            ]);

        DB::table('jobs')
            ->whereNotNull('scheduled_end_at')
            ->update([
                'scheduled_end_at' => DB::raw(
                    'DATE_ADD(scheduled_end_at, INTERVAL 7 HOUR)'
                ),
            ]);

        DB::table('job_bids')
            ->whereNotNull('proposed_start_at')
            ->update([
                'proposed_start_at' => DB::raw(
                    'DATE_ADD(proposed_start_at, INTERVAL 7 HOUR)'
                ),
            ]);
    }

    public function down(): void
    {
        // Intentionally left empty: after this correction, later rows contain
        // valid Jakarta values too and cannot safely be shifted back as a set.
    }
};
