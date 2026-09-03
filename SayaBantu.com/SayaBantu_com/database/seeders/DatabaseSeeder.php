<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\users;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            UserSeeder::class,
            MitraProfileSeeder::class,
            SystemSettingSeeder::class,
            JobSeeder::class,
            JobBidSeeder::class,
            AppReviewSeeder::class,
            NotificationSeeder::class,
            AdminActivitySeeder::class,
            SuperAdminActivitySeeder::class,
        ]);
    }
}