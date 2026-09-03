<?php
namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\roles;

class RoleSeeder extends Seeder
{
    public function run():void
    {
        roles::create(['role_name' => 'Super Admin']);
        roles::create(['role_name' => 'Admin']);
        roles::create(['role_name' => 'Mitra']);
        roles::create(['role_name' => 'Pelanggan']);
    }
}