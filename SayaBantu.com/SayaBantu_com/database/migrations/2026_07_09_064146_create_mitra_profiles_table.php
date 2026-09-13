<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mitra_profiles', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('user_id');

            // Identitas
            $table->enum('gender', ['Laki-laki', 'Perempuan'])->nullable();
            $table->date('birth_date')->nullable();
            $table->string('city')->nullable();

            // =====================================================
            // REKENING BANK (untuk terima transfer dari platform)
            // =====================================================
            $table->string('bank_name', 100)->nullable();
            $table->string('bank_account_number', 50)->nullable();
            $table->string('bank_account_name', 100)->nullable();

            // Deskripsi diri
            $table->text('bio')->nullable();
            $table->text('skills')->nullable();

            // Foto & verifikasi
            $table->json('skill_photos')->nullable();
            $table->string('verification_image', 255)->nullable();
            $table->string('selfie_image', 255)->nullable();
            $table->string('certificate', 255)->nullable();

            // Statistik
            $table->integer('point')->default(0);
            $table->decimal('rating', 3, 1)->default(0.0);
            $table->integer('jobs_completed')->default(0);

            // Verifikasi
            $table->tinyInteger('is_verified')->default(0);
            $table->unsignedInteger('verified_by')->nullable();
            $table->timestamp('verified_at')->nullable();

            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('verified_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mitra_profiles');
    }
};