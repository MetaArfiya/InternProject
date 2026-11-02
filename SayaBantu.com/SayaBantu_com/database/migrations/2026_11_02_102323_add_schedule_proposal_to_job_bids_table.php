<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('job_bids', function (Blueprint $table) {
            $table->timestamp('proposed_start_at')
                ->nullable()
                ->after('offered_price');

            $table->unsignedInteger('estimated_duration_minutes')
                ->nullable()
                ->after('proposed_start_at');
        });
    }

    public function down(): void
    {
        Schema::table('job_bids', function (Blueprint $table) {
            $table->dropColumn([
                'proposed_start_at',
                'estimated_duration_minutes',
            ]);
        });
    }
};