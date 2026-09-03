<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\users;
use App\Models\SuperAdminActivity;

class SuperAdminActivitySeeder extends Seeder
{
    public function run(): void
    {
        $superAdmin = users::whereHas('role', function ($query) {
            $query->where('role_name', 'Super Admin');
        })->first();

        if (!$superAdmin) {
            $this->command->error('Super Admin tidak ditemukan.');
            return;
        }

        SuperAdminActivity::create([
            'super_admin_id' => $superAdmin->id,
            'title' => 'Menambahkan admin baru',
            'detail' => 'Super Admin menambahkan akun admin baru.',
            'icon' => 'person_add',
            'type' => 'Admin',
        ]);

        SuperAdminActivity::create([
            'super_admin_id' => $superAdmin->id,
            'title' => 'Mengubah pengaturan sistem',
            'detail' => 'Super Admin mengubah pengaturan sistem.',
            'icon' => 'settings',
            'type' => 'Sistem',
        ]);

        SuperAdminActivity::create([
            'super_admin_id' => $superAdmin->id,
            'title' => 'Mengubah aturan poin',
            'detail' => 'Super Admin mengubah aturan poin pekerjaan.',
            'icon' => 'stars',
            'type' => 'Sistem',
        ]);

        SuperAdminActivity::create([
            'super_admin_id' => $superAdmin->id,
            'title' => 'Login ke sistem',
            'detail' => 'Super Admin berhasil login ke sistem.',
            'icon' => 'login',
            'type' => 'Login',
        ]);

        $this->command->info('Seeder aktivitas Super Admin berhasil.');
    }
}