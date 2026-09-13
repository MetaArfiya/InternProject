<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('role_id');

            $table->string('name', 255);
            $table->string('email', 255)->unique();
            $table->string('password', 255);

            $table->string('phone', 20)->nullable();
            $table->text('address')->nullable();
            $table->string('photo_profile', 255)->nullable();

            // =====================================================
            // REKENING BANK (untuk refund ke pelanggan)
            // =====================================================
            $table->string('bank_name', 100)->nullable();
            $table->string('bank_account_number', 50)->nullable();
            $table->string('bank_account_name', 100)->nullable();

            $table->boolean('is_notification_enabled')->default(true);
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();

            $table->foreign('role_id')
                ->references('id')->on('roles')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};