<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('topups', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('user_id'); 
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            
            $table->decimal('amount', 15, 2);
            $table->string('proof_url')->nullable();
            $table->string('bank_name')->nullable();
            $table->string('account_name')->nullable();
            $table->enum('status', ['pending', 'waiting_verification', 'approved', 'rejected'])->default('pending');
            $table->text('admin_note')->nullable();
            
            $table->unsignedInteger('verified_by')->nullable();
            $table->foreign('verified_by')->references('id')->on('users')->nullOnDelete();
            
            // TAMBAHKAN BARIS INI:
            $table->timestamp('verified_at')->nullable(); 
            
            $table->timestamps();

            $table->index('user_id');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('topups');
    }
};