# 🤝 SayaBantu.com

[![Project Status](https://img.shields.io/badge/status-active-brightgreen.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**SayaBantu.com** adalah platform *on-demand service & local assistance* yang menghubungkan **Pelanggan** yang membutuhkan bantuan pekerjaan harian/teknis dengan **Mitra** lokal yang siap membantu secara cepat, aman, dan terpercaya.

---

## 🌟 Fitur Utama Berdasarkan Role

Platform ini dirancang dengan sistem **Role-Based Access Control (RBAC)** yang membagi wewenang ke dalam 4 tingkatan:

### 👤 1. Pelanggan (Customer)
* Pencarian layanan berbasis lokasi otomatis (Kota/Kabupaten).
* Pemesanan jasa secara instan atau terjadwal.
* Pembayaran aman via Payment Gateway (Escrow System).
* Sistem pelacakan status pengerjaan secara real-time.
* Rating, ulasan, dan pengajuan komplain (dispute).

### 🛠️ 2. Mitra (Service Provider)
* Pendaftaran akun dengan verifikasi identitas (KYC KTP/Dokumen).
* Fitur *Toggle Status* (Online/Offline) untuk menerima pesanan.
* Dashboard manajemen tugas & riwayat pendapatan.
* Penarikan saldo (*Withdrawal*) langsung ke rekening bank/e-wallet.

### 🏙️ 3. Admin Regional (Kota/Kabupaten)
* Verifikasi & Validasi berkas pendaftaran Mitra di wilayah terkait.
* Penanganan sengketa/dispute antara Pelanggan dan Mitra lokal.
* Monitoring kualitas transaksi dan performa Mitra di area operasional.

### 👑 4. SuperAdmin
* Manajemen akun dan hak akses Admin Regional.
* Pengaturan variabel bisnis (skema komisi, fee platform, batas minimum deposit/withdraw).
* Manajemen master data (Wilayah, Kategori Jasa, Syarat & Ketentuan).
* Analytics & Laporan Keuangan Nasional.

---

## 📐 Arsitektur & Flowchart

Detail penjelasan diagram alur (*Flowchart*) untuk tiap role dapat dilihat pada file terpisah:  
📄 **[Lihat FLOWCHART.md](./FLOWCHART.md)**

---

## 🛠️ Tech Stack (Contoh Setup)

- **Frontend**: React.js / Next.js / Tailwind CSS
- **Backend**: Node.js (Express/NestJS) / Laravel
- **Database**: PostgreSQL / MySQL
- **Realtime**: Socket.io / Firebase
- **Payment Gateway**: Midtrans / Xendit

---

## 🚀 Cara Menjalankan Project (Local Development)

### Prasyarat
- Node.js (v18+) atau PHP (v8.1+)
- Database Engine (PostgreSQL / MySQL)

### Langkah Instalasi

1. **Clone repository ini**
   ```bash
   git clone https://github.com/username/sayabantu-com.git
   cd sayabantu-com
   ```

2. **Install dependensi**
   ```bash
   npm install
   # atau jika menggunakan composer
   composer install
   ```

3. **Konfigurasi Environment**
   Salin `.env.example` menjadi `.env` dan sesuaikan variabel koneksi database serta API Key:
   ```bash
   cp .env.example .env
   ```

4. **Jalankan Database Migration & Seeders**
   ```bash
   npm run db:migrate
   ```

5. **Jalankan server lokal**
   ```bash
   npm run dev
   ```

---

## 📝 Lisensi

Project ini dilindungi di bawah lisensi [MIT License](LICENSE).