<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('withdrawals', function (Blueprint $table) {
            $table->id();
            
            $table->unsignedInteger('user_id'); 
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            
            $table->decimal('amount', 15, 2);
            $table->string('bank_name');
            $table->string('account_number');
            $table->string('account_name');
            
            $table->enum('status', ['pending', 'approved', 'rejected', 'transferred'])
                  ->default('pending');
            
            $table->string('transfer_proof_url')->nullable();
            $table->string('transfer_reference')->nullable(); // <-- BARU: No. Referensi Transfer
            $table->text('admin_note')->nullable();
            
            $table->unsignedInteger('processed_by')->nullable();
            $table->foreign('processed_by')->references('id')->on('users')->nullOnDelete();
            $table->timestamp('processed_at')->nullable();
            
            // <-- BARU: Waktu user konfirmasi terima uang
            $table->timestamp('customer_received_at')->nullable(); 
            
            $table->timestamps();

            $table->index('user_id');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('withdrawals');
    }
};