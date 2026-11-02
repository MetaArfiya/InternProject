<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\users;
use App\Models\Wallet;

class WalletSeeder extends Seeder
{
    public function run(): void
    {
        users::query()->chunk(200, function ($users) {
            foreach ($users as $user) {
                Wallet::firstOrCreate(
                    ['user_id' => $user->id],
                    ['balance' => 0, 'held_balance' => 0]
                );
            }
        });
    }
}