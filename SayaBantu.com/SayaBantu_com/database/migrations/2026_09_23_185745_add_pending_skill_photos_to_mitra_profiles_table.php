<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mitra_profiles', function (Blueprint $table) {
            // Foto keahlian yang diajukan, menunggu ACC admin
            $table->json('pending_skill_photos')->nullable()->after('pending_skills');
        });
    }

    public function down(): void
    {
        Schema::table('mitra_profiles', function (Blueprint $table) {
            $table->dropColumn('pending_skill_photos');
        });
    }
};