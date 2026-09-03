<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('superadmin_activities', function (Blueprint $table) {
            $table->id();

            // User Super Admin yang melakukan aktivitas
            $table->unsignedInteger('super_admin_id');

            // Judul aktivitas
            $table->string('title');

            // Detail aktivitas
            $table->text('detail')->nullable();

            // Nama icon Flutter
            // contoh: settings, edit, delete, login, stars
            $table->string('icon')->nullable();

            // Tipe aktivitas
            // contoh: Sistem, Admin, Login
            $table->string('type')->default('Sistem');

            $table->timestamps();

            // Relasi ke tabel users
            $table->foreign('super_admin_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('superadmin_activities');
    }
};