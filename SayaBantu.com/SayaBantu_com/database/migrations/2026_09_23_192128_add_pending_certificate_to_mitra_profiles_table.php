<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mitra_profiles', function (Blueprint $table) {
            $table->string('pending_certificate', 255)->nullable()->after('pending_skill_photos');
        });
    }

    public function down(): void
    {
        Schema::table('mitra_profiles', function (Blueprint $table) {
            $table->dropColumn('pending_certificate');
        });
    }
};