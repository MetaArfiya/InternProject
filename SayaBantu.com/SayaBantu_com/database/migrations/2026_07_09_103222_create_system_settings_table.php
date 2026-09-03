<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('system_settings', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('updated_by')->default(1);
            $table->integer('points_on_completion')->default(10);
            $table->integer('points_on_cancellation')->default(5);
            $table->integer('points_bonus_rating')->default(3);
            $table->decimal('platform_commission_percent', 5, 2)->default(15.00);
            $table->timestamps();

            $table->foreign('updated_by')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('system_settings');
    }
};