<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('jobs', function (Blueprint $table) {
            $table->timestamp('preferred_start_at')
                ->nullable()
                ->after('duration');

            $table->timestamp('scheduled_start_at')
                ->nullable()
                ->after('preferred_start_at');

            $table->timestamp('scheduled_end_at')
                ->nullable()
                ->after('scheduled_start_at');

            $table->index(
                ['mitra_id', 'status', 'scheduled_start_at', 'scheduled_end_at'],
                'jobs_mitra_schedule_index'
            );
        });
    }

    public function down(): void
    {
        Schema::table('jobs', function (Blueprint $table) {
            $table->dropIndex('jobs_mitra_schedule_index');

            $table->dropColumn([
                'preferred_start_at',
                'scheduled_start_at',
                'scheduled_end_at',
            ]);
        });
    }
};