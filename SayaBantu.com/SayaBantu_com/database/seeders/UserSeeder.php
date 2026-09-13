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
            'bank_name' => 'BCA',
            'bank_account_number' => '1111111111',
            'bank_account_name' => 'Super Admin Boss',
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
            'bank_name' => 'Mandiri',
            'bank_account_number' => '2222222222',
            'bank_account_name' => 'Siti Rahayu',
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
            'bank_name' => 'BRI',
            'bank_account_number' => '3333333333',
            'bank_account_name' => 'Deni Kusuma',
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
            'bank_name' => 'BNI',
            'bank_account_number' => '4444444444',
            'bank_account_name' => 'Rina Wijaya',
            'is_active' => false,
            'last_login_at' => now()->subDays(3),
        ]);

        // Mitra
        $mitras = [
            ['Pak Budi Setyawan', 'Budi@sayabantu.com', '081355555555', 'Jl. Kebon Jeruk No. 5, Jakarta Barat', 'BCA', '5555555555'],
            ['Mas Eko Prasetyo', 'Eko@sayabantu.com', '081366666666', 'Jl. Mangga Dua No. 6, Jakarta Utara', 'Mandiri', '6666666666'],
            ['Pak Joko Wirawan', 'Joko@sayabantu.com', '081377777777', 'Jl. Tebet Raya No. 7, Jakarta Selatan', 'BRI', '7777777777'],
            ['Ahmad Fauzi', 'Ahmad@sayabantu.com', '081388888888', 'Jl. Cikini Raya No. 8, Jakarta Pusat', 'BNI', '8888888888'],
            ['Dewi Lestari', 'Dewi@sayabantu.com', '081399999999', 'Jl. Salemba Raya No. 9, Jakarta Pusat', 'BCA', '9999999999'],
            ['Rudi Hartono', 'Rudi@sayabantu.com', '081300000000', 'Jl. Matraman No. 10, Jakarta Timur', 'CIMB Niaga', '1010101010'],
        ];

        foreach ($mitras as $m) {
            users::create([
                'role_id' => 3,
                'name' => $m[0],
                'email' => $m[1],
                'password' => Hash::make('password123'),
                'phone' => $m[2],
                'address' => $m[3],
                'bank_name' => $m[4],
                'bank_account_number' => $m[5],
                'bank_account_name' => $m[0],
                'is_active' => true,
            ]);
        }

        // Pelanggan
        $pelanggans = [
            ['Anisa Nurhayati', 'pelanggan@sayabantu.com', '081811111111', 'Jl. Prapanca No. 11, Jakarta Selatan', 'BCA', '8111111111'],
            ['Budi Santoso', 'budi@gmail.com', '081822222222', 'Jl. Kemang Raya No. 12, Jakarta Selatan', 'Mandiri', '8222222222'],
            ['Spammer123', 'Spammer123@sayabantu.com', '081833333333', 'Jl. Antasari No. 13, Jakarta Selatan', 'BRI', '8333333333'],
            ['Sari Dewi', 'Sari@sayabantu.com', '081844444444', 'Jl. Senopati No. 14, Jakarta Selatan', 'BNI', '8444444444'],
        ];

        foreach ($pelanggans as $p) {
            users::create([
                'role_id' => 4,
                'name' => $p[0],
                'email' => $p[1],
                'password' => Hash::make('password123'),
                'phone' => $p[2],
                'address' => $p[3],
                'bank_name' => $p[4],
                'bank_account_number' => $p[5],
                'bank_account_name' => $p[0],
                'is_active' => true,
            ]);
        }
    }
}