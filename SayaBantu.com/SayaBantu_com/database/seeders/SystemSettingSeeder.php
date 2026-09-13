<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class SystemSettingSeeder extends Seeder
{
    public function run(): void
    {
        \App\Models\system_setting::create([
            'updated_by' => 1,
            'points_on_completion' => 10,
            'points_on_cancellation' => 5,
            'points_bonus_rating' => 3,
            'platform_commission_percent' => 15.00,

            // =====================================================
            // REKENING PLATFORM (contoh)
            // =====================================================
            'platform_bank_name' => 'BCA',
            'platform_bank_account_number' => '1234567890',
            'platform_bank_account_name' => 'PT Sayabantu Indonesia',
        ]);
    }
}