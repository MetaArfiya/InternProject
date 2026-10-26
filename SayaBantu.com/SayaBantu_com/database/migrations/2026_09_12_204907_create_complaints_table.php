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

            $table->unsignedInteger('user_id');
            $table->enum('user_role', ['Mitra', 'Pelanggan']);

            $table->enum('category', [
                'Pelanggan Bermasalah',
                'Mitra Bermasalah',
                'Pembayaran',
                'Pekerjaan',
                'Aplikasi',
                'Lainnya',
            ]);

            $table->string('title', 255);
            $table->text('description');

            // Relasi ke job (opsional)
            $table->unsignedInteger('job_id')->nullable();

            // Bukti foto (path file di storage)
            $table->string('proof_photo')->nullable();

            $table->enum('status', [
                'Menunggu',
                'Diproses',
                'Selesai',
                'Ditolak',
            ])->default('Menunggu');

            $table->text('admin_response')->nullable();
            $table->unsignedInteger('handled_by')->nullable();
            $table->timestamp('handled_at')->nullable();

            $table->timestamps();

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