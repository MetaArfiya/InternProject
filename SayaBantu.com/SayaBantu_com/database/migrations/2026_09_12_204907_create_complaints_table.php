<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('complaints', function (Blueprint $table) {
            $table->increments('id');

            // Siapa yang mengadu
            $table->unsignedInteger('user_id');

            // Role pengadu: mitra atau pelanggan
            $table->enum('user_role', ['Mitra', 'Pelanggan']);

            // Kategori
            $table->enum('category', [
                'Pelanggan Bermasalah',
                'Mitra Bermasalah',
                'Pembayaran',
                'Pekerjaan',
                'Aplikasi',
                'Lainnya',
            ]);

            // Isi pengaduan
            $table->string('title', 255);
            $table->text('description');

            // Relasi ke job (opsional)
            $table->unsignedInteger('job_id')->nullable();

            // Status tindak lanjut
            $table->enum('status', [
                'Menunggu',
                'Diproses',
                'Selesai',
                'Ditolak',
            ])->default('Menunggu');

            // Tanggapan admin
            $table->text('admin_response')->nullable();
            $table->unsignedInteger('handled_by')->nullable();
            $table->timestamp('handled_at')->nullable();

            $table->timestamps();

            // Foreign keys
            $table->foreign('user_id')
                ->references('id')->on('users')
                ->onDelete('cascade');

            $table->foreign('job_id')
                ->references('id')->on('jobs')
                ->onDelete('set null');

            $table->foreign('handled_by')
                ->references('id')->on('users')
                ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('complaints');
    }
};