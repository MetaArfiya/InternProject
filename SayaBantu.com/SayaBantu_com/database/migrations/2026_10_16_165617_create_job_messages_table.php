<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('job_messages', function (Blueprint $table) {
            $table->increments('id');

            // Refer ke jobs.id → INT UNSIGNED (karena $table->increments di jobs)
            $table->unsignedInteger('job_id');

            // Refer ke users.id → sesuaikan jika users pakai bigIncrements
            $table->unsignedInteger('sender_id');

            $table->text('message');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->foreign('job_id')
                ->references('id')->on('jobs')
                ->onDelete('cascade');

            $table->foreign('sender_id')
                ->references('id')->on('users')
                ->onDelete('cascade');

            $table->index(['job_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('job_messages');
    }
};