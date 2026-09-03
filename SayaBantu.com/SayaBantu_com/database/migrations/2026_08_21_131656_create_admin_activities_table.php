<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin_activities', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('admin_id')->nullable(); // Siapa admin yang bertindak
            $table->text('title'); // Deskripsi aktivitas (misal: "Mitra Dewi Lestari berhasil diverifikasi")
            $table->string('icon')->default('verified'); // Jenis icon
            $table->string('color_type')->default('green'); // Warna penanda
            $table->timestamps();

            // Jika ada relasi ke tabel users:
            // $table->foreign('admin_id')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_activities');
    }
};