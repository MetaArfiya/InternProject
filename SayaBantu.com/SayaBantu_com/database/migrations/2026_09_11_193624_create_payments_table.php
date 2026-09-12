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

            // Relasi
            $table->unsignedInteger('job_id');
            $table->unsignedInteger('pelanggan_id');
            $table->unsignedInteger('mitra_id')->nullable();

            // Nominal
            $table->decimal('job_amount', 12, 2);
            $table->decimal('commission_percent', 5, 2);
            $table->decimal('commission_amount', 12, 2);
            $table->decimal('total_paid', 12, 2);
            $table->decimal('mitra_earning', 12, 2);

            // Status
            $table->enum('status', [
                'pending',
                'paid',
                'settled',
                'failed',
                'refunded',
            ])->default('pending');

            // Metode pembayaran
            $table->string('payment_method', 50)->nullable(); // transfer, ewallet, dll
            $table->string('reference_code', 100)->nullable()->unique(); // kode unik

            // Timestamp
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('settled_at')->nullable();

            $table->timestamps();

            // Foreign keys
            $table->foreign('job_id')->references('id')->on('jobs')->onDelete('cascade');
            $table->foreign('pelanggan_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('mitra_id')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};