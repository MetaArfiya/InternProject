<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
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
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->text('location_description')->nullable();
            $table->string('image_url', 255)->nullable();

            $table->decimal('initial_budget', 12, 2);
            $table->decimal('final_price', 12, 2)->nullable();

            $table->string('duration', 50)->nullable();

            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();

            $table->enum('status', [
                'Mencari Mitra',
                'Sedang Dikerjakan',
                'Menunggu Konfirmasi Selesai',
                'Selesai',
                'Dibatalkan'
            ])->default('Mencari Mitra');

            $table->tinyInteger('is_verified')->default(0);
            $table->unsignedInteger('verified_by')->nullable();
            $table->timestamps();

            // Foreign keys
            $table->foreign('pelanggan_id')
                  ->references('id')->on('users')->onDelete('cascade');
            $table->foreign('mitra_id')
                  ->references('id')->on('users')->onDelete('set null');
            $table->foreign('verified_by')
                  ->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jobs');
    }
};