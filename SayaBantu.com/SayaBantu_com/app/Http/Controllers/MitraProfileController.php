<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\mitra_profiles;
use Illuminate\Support\Facades\Storage;
use App\Models\users;
use App\Notifications\NewMitraRegistered;

class MitraProfileController extends Controller
{
    public function uploadKtp(Request $request)
    {
        // 1. Validasi file saja
        $request->validate([
            'ktp_file' => 'required|image|mimes:jpeg,png,jpg|max:2048',
            'certificates' => 'nullable|array',
            'certificates.*' => 'image|mimes:jpeg,png,jpg|max:2048',
        ]);

        // 2. Cari profil berdasarkan ID users yang sedang login saat ini
        $profile = mitra_profiles::where('user_id', auth()->id())->first();

        if (!$profile) {
            return response()->json(['message' => 'Profil Mitra tidak ditemukan!'], 404);
        }

        // 3. Hapus KTP lama jika ada di server
        if ($profile->verification_image && Storage::disk('public')->exists($profile->verification_image)) {
            Storage::disk('public')->delete($profile->verification_image);
        }
        
        // Simpan KTP baru
        $ktpPath = $request->file('ktp_file')->store('ktp_berkas', 'public');

        // 4. Mengelola sertifikat yang diunggah
        $sertifikatArray = $profile->certificate ?? [];

        if ($request->hasFile('certificates')) {
            // Hapus sertifikat lama di storage jika ingin diganti total
            if (!empty($sertifikatArray)) {
                foreach ($sertifikatArray as $oldCert) {
                    if (Storage::disk('public')->exists($oldCert)) {
                        Storage::disk('public')->delete($oldCert);
                    }
                }
                $sertifikatArray = []; // Reset array
            }

            // Loop untuk menyimpan file-file sertifikat yang baru diunggah
            foreach ($request->file('certificates') as $file) {
                $pathCert = $file->store('sertifikat_berkas', 'public');
                $sertifikatArray[] = $pathCert; 
            }
        }

        // 5. Update database dengan data baru
        $profile->update([
            'verification_image' => $ktpPath,
            'certificate' => $sertifikatArray,
        ]);

        // 6. [DIPINDAHKAN KE SINI] KIRIM NOTIFIKASI KE SEMUA ADMIN 
        $mitra = auth()->user();

        $admins = users::whereHas('roles', function($query) {
            $query->where('name', 'Admin'); 
        })->get();

        foreach ($admins as $admin) {
            $admin->notify(new NewMitraRegistered($mitra));
        }

        // 7. Mengubah path menjadi URL lengkap untuk response
        $certificateUrls = array_map(function ($path) {
            return asset('storage/' . $path);
        }, $sertifikatArray);

        return response()->json([
            'message'  => 'Berkas KTP dan Sertifikat berhasil diunggah! Menunggu verifikasi harian oleh Admin.',
            'success'  => true,
            'data' => [
                'url_ktp' => asset('storage/' . $ktpPath),
                'url_sertifikat' => $certificateUrls 
            ]
        ], 200);
    }

    public function show($id)
    {
        try {
            $mitra = users::find($id);

            if (!$mitra) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Data mitra tidak ditemukan'
                ], 404);
            }

            // 1. Ambil Data Profil Mitra
            $profile = mitra_profiles::where('user_id', $mitra->id)->first();

            // 2. Parsel Keahlian (Skills)
            $skillsArray = [];
            if ($profile && !empty($profile->skills)) {
                $skillsArray = array_map('trim', explode(',', $profile->skills));
            }

            // 3. Hitung Rating & Jumlah Review
            $ratingVal = $profile && $profile->rating !== null ? (float)$profile->rating : 0.0;
            
            $reviewsCount = 0; 
            $reviewsList  = []; 

            // 4. Hitung Persentase Kepuasan berdasarkan Rating (Skala 5.0 -> 100%)
            $satisfactionPercentage = $ratingVal > 0 ? round(($ratingVal / 5.0) * 100) . '%' : '0%';

            // 5. Hitung Job Selesai
            $jobsCompletedCount = $profile->jobs_completed ?? 0;

            // 6. Tahun Bergabung
            $joinedYear = $mitra->created_at ? $mitra->created_at->format('Y') : date('Y');

            return response()->json([
                'status' => 'success',
                'data'   => [
                    'id'             => $mitra->id,
                    'name'           => $mitra->name ?? 'Mitra',
                    'rating'         => $ratingVal,
                    'reviews_count'  => $reviewsCount,
                    'verified'       => $profile ? ((int)$profile->is_verified === 1) : false,
                    'jobs_completed' => $jobsCompletedCount,
                    'satisfaction'   => $satisfactionPercentage,
                    'joined_year'    => $joinedYear,
                    'about'          => $profile->bio ?? 'Belum ada deskripsi profil.',
                    'skills'         => !empty($skillsArray) ? $skillsArray : ['Belum ada keahlian'],
                    'reviews'        => $reviewsList
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Server Error: ' . $e->getMessage()
            ], 500);
        }
    }

    public function getProfile(Request $request)
    {
        try {
            $user = auth()->user();
            $profile = mitra_profiles::where('user_id', $user->id)->first();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'point' => $profile ? ($profile->point ?? 0) : 0,
                    'is_verified' => $profile ? (int)$profile->is_verified === 1 : false,
                ]
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }
}