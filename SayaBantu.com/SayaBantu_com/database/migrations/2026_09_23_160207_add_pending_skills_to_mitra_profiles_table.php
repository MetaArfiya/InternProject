<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mitra_profiles', function (Blueprint $table) {
            // Keahlian yang diajukan, menunggu ACC admin
            $table->string('pending_skills', 255)->nullable()->after('skills');

            // Kapan terakhir kali skill diubah/diajukan
            $table->timestamp('skills_updated_at')->nullable()->after('pending_skills');

            // Catatan admin saat approve/reject
            $table->text('skill_admin_note')->nullable()->after('skills_updated_at');
        });
    }

    public function down(): void
    {
        Schema::table('mitra_profiles', function (Blueprint $table) {
            $table->dropColumn(['pending_skills', 'skills_updated_at', 'skill_admin_note']);
        });
    }
};