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
        Schema::create('mitra_profiles', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('user_id');
            
            // Kolom phone_number sudah dihapus dari sini
            
            $table->text('bio')->nullable();
            $table->text('skills')->nullable();
            
            $table->string('verification_image', 255)->nullable();
            $table->string('certificate', 255)->nullable();
            $table->integer('point')->default(0);
            $table->decimal('rating', 3, 1)->default(0.0);
            $table->tinyInteger('is_verified')->default(0);
            $table->unsignedInteger('verified_by')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('verified_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mitra_profiles');
    }
};