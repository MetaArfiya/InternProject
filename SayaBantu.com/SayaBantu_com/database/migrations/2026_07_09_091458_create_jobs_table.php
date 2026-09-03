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
        Schema::create('jobs', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('pelanggan_id');
            $table->unsignedInteger('mitra_id')->nullable();
            $table->string('tittle', 255);
            $table->text('description');
            $table->string('category', 100)->nullable();
            $table->string('location', 255)->nullable();
            $table->string('image_url', 255)->nullable();
            $table->decimal('initial_budget', 12, 2);
            $table->decimal('final_price', 12, 2)->nullable();
            $table->enum('status', ['Mencari Mitra', 'Sedang Dikerjakan', 'Selesai', 'Dibatalkan'])->default('Mencari Mitra');
            
            // Kolom tambahan sesuai gambar
            $table->tinyInteger('is_verified')->default(0);
            $table->unsignedInteger('verified_by')->nullable();

            $table->timestamps();

            // Foreign Key
            $table->foreign('pelanggan_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('mitra_id')->references('id')->on('users')->onDelete('set null');
            $table->foreign('verified_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('jobs');
    }
};