<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->increments('id');

            $table->unsignedInteger('job_id');
            $table->unsignedInteger('pelanggan_id');
            $table->unsignedInteger('mitra_id');

            $table->decimal('job_amount', 15, 2);
            $table->decimal('commission_percent', 5, 2);
            $table->decimal('commission_amount', 15, 2);
            $table->decimal('total_paid', 15, 2);
            $table->decimal('mitra_earning', 15, 2);

            // pending | waiting_verification | paid | settled | refunded | failed
            $table->string('status', 30)->default('pending');
            $table->string('payment_method', 50)->nullable();
            $table->string('reference_code', 50)->unique();

            // =====================================================
            // BUKTI DARI PELANGGAN (transfer ke platform)
            // =====================================================
            $table->string('customer_proof_url', 255)->nullable();
            $table->timestamp('customer_proof_uploaded_at')->nullable();
            $table->string('customer_bank_name', 100)->nullable();
            $table->string('customer_account_name', 100)->nullable();

            // =====================================================
            // BUKTI DARI ADMIN (transfer ke mitra)
            // =====================================================
            $table->string('mitra_proof_url', 255)->nullable();
            $table->timestamp('mitra_proof_uploaded_at')->nullable();
            $table->string('admin_note', 500)->nullable();

            // Timestamps status
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('settled_at')->nullable();

            $table->timestamps();

            $table->foreign('job_id')->references('id')->on('jobs')->onDelete('cascade');
            $table->foreign('pelanggan_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('mitra_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};