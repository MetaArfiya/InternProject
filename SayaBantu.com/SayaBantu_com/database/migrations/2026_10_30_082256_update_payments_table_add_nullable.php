<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->unsignedInteger('mitra_id')->nullable()->change();
            $table->decimal('commission_percent', 5, 2)->nullable()->change();
            $table->decimal('commission_amount', 15, 2)->nullable()->change();
            $table->decimal('mitra_earning', 15, 2)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->unsignedInteger('mitra_id')->nullable(false)->change();
            $table->decimal('commission_percent', 5, 2)->nullable(false)->change();
            $table->decimal('commission_amount', 15, 2)->nullable(false)->change();
            $table->decimal('mitra_earning', 15, 2)->nullable(false)->change();
        });
    }
};