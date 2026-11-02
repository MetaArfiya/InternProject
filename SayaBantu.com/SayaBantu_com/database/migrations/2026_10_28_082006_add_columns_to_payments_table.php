<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->timestamp('held_at')->nullable()->after('paid_at');
            $table->timestamp('customer_accepted_at')->nullable()->after('held_at');
            $table->timestamp('released_at')->nullable()->after('customer_accepted_at');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn(['held_at', 'customer_accepted_at', 'released_at']);
        });
    }
};