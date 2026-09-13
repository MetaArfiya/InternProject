<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ratings', function (Blueprint $table) {
            $table->increments('id');

            // Relasi
            $table->unsignedInteger('job_id');
            $table->unsignedInteger('mitra_id');
            $table->unsignedInteger('pelanggan_id');

            // Penilaian
            $table->tinyInteger('stars'); // 1-5
            $table->text('comment')->nullable();

            // Moderasi admin (hide, bukan delete)
            $table->tinyInteger('is_hidden')->default(0);
            $table->unsignedInteger('hidden_by')->nullable();
            $table->timestamp('hidden_at')->nullable();
            $table->text('hidden_reason')->nullable();

            $table->timestamps();

            // Unique: 1 job hanya bisa dirating 1x oleh pelanggan
            $table->unique(['job_id', 'pelanggan_id']);

            // Foreign keys
            $table->foreign('job_id')->references('id')->on('jobs')->onDelete('cascade');
            $table->foreign('mitra_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('pelanggan_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('hidden_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ratings');
    }
};