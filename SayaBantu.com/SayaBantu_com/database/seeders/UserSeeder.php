<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\users;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Super Admin
        users::create([
            'role_id' => 1,
            'name' => 'Super Admin Boss',
            'email' => 'superadmin@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081111111111',
            'address' => 'Jl. Sudirman No. 1, Jakarta Pusat',
            'is_active' => true,
            'last_login_at' => now()->subHours(2),
        ]);

        // Admin 
        users::create([
            'role_id' => 2,
            'name' => 'Siti Rahayu',
            'email' => 'Siti@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081222222222',
            'address' => 'Jl. Gatot Subroto No. 2, Jakarta Selatan',
            'is_active' => true,
            'last_login_at' => now()->subHours(1),
        ]);

        users::create([
            'role_id' => 2,
            'name' => 'Deni Kusuma',
            'email' => 'Deni@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081233333333',
            'address' => 'Jl. Rasuna Said No. 3, Jakarta Selatan',
            'is_active' => true,
            'last_login_at' => now()->subHours(5),
        ]);

        users::create([
            'role_id' => 2,
            'name' => 'Rina Wijaya',
            'email' => 'Rina@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081244444444',
            'address' => 'Jl. MH Thamrin No. 4, Jakarta Pusat',
            'is_active' => false,
            'last_login_at' => now()->subDays(3),
        ]);

        // Mitra
        users::create([
            'role_id' => 3,
            'name' => 'Pak Budi Setyawan',
            'email' => 'Budi@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081355555555',
            'address' => 'Jl. Kebon Jeruk No. 5, Jakarta Barat',
        ]);

        users::create([
            'role_id' => 3,
            'name' => 'Mas Eko Prasetyo',
            'email' => 'Eko@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081366666666',
            'address' => 'Jl. Mangga Dua No. 6, Jakarta Utara',
        ]);

        users::create([
            'role_id' => 3,
            'name' => 'Pak Joko Wirawan',
            'email' => 'Joko@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081377777777',
            'address' => 'Jl. Tebet Raya No. 7, Jakarta Selatan',
        ]);

        // Mitra Belum Verif
        users::create([
            'role_id' => 3,
            'name' => 'Ahmad Fauzi',
            'email' => 'Ahmad@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081388888888',
            'address' => 'Jl. Cikini Raya No. 8, Jakarta Pusat',
        ]);

        users::create([
            'role_id' => 3,
            'name' => 'Dewi Lestari',
            'email' => 'Dewi@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081399999999',
            'address' => 'Jl. Salemba Raya No. 9, Jakarta Pusat',
        ]);

        users::create([
            'role_id' => 3,
            'name' => 'Rudi Hartono',
            'email' => 'Rudi@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081300000000',
            'address' => 'Jl. Matraman No. 10, Jakarta Timur',
        ]);

        // Pelanggan
        users::create([
            'role_id' => 4,
            'name' => 'Anisa Nurhayati',
            'email' => 'pelanggan@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081811111111',
            'address' => 'Jl. Prapanca No. 11, Jakarta Selatan',
        ]);

        users::create([
            'role_id' => 4,
            'name' => 'Budi Santoso',
            'email' => 'budi@gmail.com',
            'password' => Hash::make('password123'),
            'phone' => '081822222222',
            'address' => 'Jl. Kemang Raya No. 12, Jakarta Selatan',
        ]);

        users::create([
            'role_id' => 4,
            'name' => 'Spammer123',
            'email' => 'Spammer123@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081833333333',
            'address' => 'Jl. Antasari No. 13, Jakarta Selatan',
        ]);

        users::create([
            'role_id' => 4,
            'name' => 'Sari Dewi',
            'email' => 'Sari@sayabantu.com',
            'password' => Hash::make('password123'),
            'phone' => '081844444444',
            'address' => 'Jl. Senopati No. 14, Jakarta Selatan',
        ]);
    }
}