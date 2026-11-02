<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement("
        ALTER TABLE jobs
        MODIFY status ENUM(
            'Mencari Mitra',
            'Terjadwal',
            'Sedang Dikerjakan',
            'Menunggu Konfirmasi Selesai',
            'Selesai',
            'Dibatalkan'
        ) NOT NULL DEFAULT 'Mencari Mitra'
    ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('jobs', function (Blueprint $table) {
            //
        });
    }
};
