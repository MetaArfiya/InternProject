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
        Schema::create('mitra_profiles', function (Blueprint $table) {
            $table->increments('id');

            // =========================================================
            // RELASI USER
            // =========================================================
            $table->unsignedInteger('user_id');

            // =========================================================
            // IDENTITAS MITRA
            // =========================================================
            $table->enum('gender', [
                'Laki-laki',
                'Perempuan'
            ])->nullable();

            $table->date('birth_date')->nullable();

            $table->string('city')->nullable();

            // =========================================================
            // DESKRIPSI DIRI
            // Flutter: description
            // Database: bio
            // =========================================================
            $table->text('bio')->nullable();

            // =========================================================
            // KEAHLIAN
            // Flutter: selectedCategory
            // Database: skills
            //
            // Contoh:
            // "Service AC"
            // "Plumbing"
            // "Listrik"
            // =========================================================
            $table->text('skills')->nullable();

            // =========================================================
            // FOTO HASIL PEKERJAAN / FOTO KEAHLIAN
            // Maksimal 6 foto dari Flutter
            //
            // Disimpan dalam bentuk JSON array.
            //
            // Contoh:
            // [
            //   "skills/foto1.jpg",
            //   "skills/foto2.jpg"
            // ]
            // =========================================================
            $table->json('skill_photos')->nullable();

            // =========================================================
            // DOKUMEN VERIFIKASI
            // =========================================================
            $table->string('verification_image', 255)->nullable();

            $table->string('selfie_image', 255)->nullable();

            $table->string('certificate', 255)->nullable();

            // =========================================================
            // POIN & RATING
            // =========================================================
            $table->integer('point')->default(0);

            $table->decimal('rating', 3, 1)->default(0.0);

            // =========================================================
            // STATUS VERIFIKASI
            // =========================================================
            $table->tinyInteger('is_verified')->default(0);

            $table->unsignedInteger('verified_by')->nullable();

            $table->timestamp('verified_at')->nullable();

            // =========================================================
            // TIMESTAMPS
            // =========================================================
            $table->timestamps();

            // =========================================================
            // FOREIGN KEY
            // =========================================================
            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade');

            $table->foreign('verified_by')
                ->references('id')
                ->on('users')
                ->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mitra_profiles');
    }
};