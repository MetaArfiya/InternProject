<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('jobs', function (Blueprint $table) {
            $table->decimal('location_lat', 10, 7)->nullable();
            $table->decimal('location_lng', 10, 7)->nullable();
            $table->decimal('mitra_lat', 10, 7)->nullable();
            $table->decimal('mitra_lng', 10, 7)->nullable();
            $table->timestamp('mitra_location_updated_at')->nullable();
            $table->decimal('distance_km', 8, 2)->nullable();
            $table->integer('eta_minutes')->nullable();
            $table->string('tracking_status', 20)->nullable();
            $table->timestamp('tracking_started_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('jobs', function (Blueprint $table) {
            $table->dropColumn([
                'location_lat', 'location_lng',
                'mitra_lat', 'mitra_lng',
                'mitra_location_updated_at',
                'distance_km', 'eta_minutes',
                'tracking_status', 'tracking_started_at',
            ]);
        });
    }
};