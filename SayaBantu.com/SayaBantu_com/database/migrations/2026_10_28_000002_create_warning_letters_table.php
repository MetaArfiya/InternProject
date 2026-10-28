<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('warning_letters', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('user_id');
            $table->unsignedInteger('admin_id');
            $table->string('recipient_role', 20);
            $table->unsignedTinyInteger('level');
            $table->string('subject', 150);
            $table->text('reason');
            $table->timestamps();
            $table->index(['user_id', 'created_at']);
            $table->index(['admin_id', 'created_at']);
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('admin_id')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('warning_letters');
    }
};
