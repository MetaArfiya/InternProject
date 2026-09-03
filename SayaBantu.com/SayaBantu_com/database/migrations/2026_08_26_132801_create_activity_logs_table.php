<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('activity_logs', function (Blueprint $table) {
            $table->id();

            // User yang melakukan aktivitas
            $table->unsignedInteger('user_id');

            // Judul aktivitas
            $table->string('title');

            // Detail aktivitas
            $table->text('detail')->nullable();

            // Icon Flutter
            $table->string('icon')->nullable();

            // Admin / Sistem / Login / Mitra / Pelanggan
            $table->string('type')->default('Sistem');

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('activity_logs');
    }
};