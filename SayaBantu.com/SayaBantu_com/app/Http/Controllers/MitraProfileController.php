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

    public function updateProfile(Request $request)
    {
        try {
            $user = auth()->user();

            $profile = mitra_profiles::where('user_id', $user->id)->first();

            if (!$profile) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Profil Mitra tidak ditemukan.'
                ], 404);
            }

            $request->validate([
                'gender' => 'nullable|string|max:50',
                'birth_date' => 'nullable|date',
                'city' => 'nullable|string|max:100',
                'bio' => 'nullable|string',
                'skills' => 'nullable|string|max:255',
            ]);

            $updateData = [];

            if ($request->has('gender')) {
                $updateData['gender'] = $request->gender;
            }

            if ($request->has('birth_date')) {
                $updateData['birth_date'] = $request->birth_date;
            }

            if ($request->has('city')) {
                $updateData['city'] = $request->city;
            }

            if ($request->has('bio')) {
                $updateData['bio'] = $request->bio;
            }

            if ($request->has('skills')) {
                $updateData['skills'] = $request->skills;
            }

            $profile->update($updateData);

            return response()->json([
                'status' => 'success',
                'message' => 'Profil Mitra berhasil diperbarui.',
                'data' => [
                    'gender' => $profile->gender,
                    'birth_date' => $profile->birth_date,
                    'city' => $profile->city,
                    'bio' => $profile->bio,
                    'skills' => $profile->skills,
                    'point' => $profile->point ?? 0,
                    'rating' => $profile->rating ?? 0,
                    'is_verified' => (int) $profile->is_verified === 1,
                ]
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function getProfile(Request $request)
    {
        try {
            $user = auth()->user();

            $profile = mitra_profiles::where('user_id', $user->id)->first();

            if (!$profile) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Profil Mitra tidak ditemukan.'
                ], 404);
            }

            // Pecah skills menjadi array jika datanya dipisahkan koma
            $skillsArray = [];

            if (!empty($profile->skills)) {
                $skillsArray = array_values(
                    array_filter(
                        array_map('trim', explode(',', $profile->skills))
                    )
                );
            }

            return response()->json([
                'status' => 'success',

                'data' => [
                    'id' => $user->id,
                    'name' => $user->name,

                    // Data user
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'address' => $user->address,

                    // Data profil mitra
                    'gender' => $profile->gender,
                    'birth_date' => $profile->birth_date,
                    'city' => $profile->city,
                    'bio' => $profile->bio,

                    // Skills tetap dikirim sebagai array
                    'skills' => $skillsArray,

                    // Statistik
                    'point' => $profile->point ?? 0,
                    'rating' => $profile->rating ?? 0,
                    'is_verified' => (int)$profile->is_verified === 1,

                    // Berkas jika nanti diperlukan frontend
                    'verification_image' => $profile->verification_image,
                    'selfie_image' => $profile->selfie_image,
                    'certificate' => $profile->certificate,
                    'skill_photos' => $profile->skill_photos,
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function submitVerification(Request $request)
    {
        try {
            $request->validate([
                'ktp_file' => 'required|image|mimes:jpeg,png,jpg|max:2048',
                'selfie_file' => 'required|image|mimes:jpeg,png,jpg|max:2048',
            ]);

            $user = auth()->user();
            $profile = mitra_profiles::where('user_id', $user->id)->first();

            if (!$profile) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Profil mitra tidak ditemukan.'
                ], 404);
            }

            // Simpan file
            $ktpPath = $request->file('ktp_file')->store('profile_photos', 'public');
            $selfiePath = $request->file('selfie_file')->store('profile_photos', 'public');

            $profile->update([
                'verification_image' => $ktpPath,
                'selfie_image' => $selfiePath,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Verifikasi berhasil dikirim.',
                'verification_image' => $ktpPath,  // ← kirim
                'selfie_image' => $selfiePath,     // ← kirim
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    public function uploadSkillPhotos(Request $request)
    {
        $request->validate([
            'photos.*' => 'image|max:2048',
        ]);

        $profile = mitra_profiles::where('user_id', auth()->id())->first();

        if (!$profile) {
            return response()->json(['message' => 'Profil tidak ditemukan'], 404);
        }

        $paths = [];
        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $photo) {
                $path = $photo->store('skill_photos', 'public');
                $paths[] = $path;
            }
        }

        // Gabung dengan foto lama (jika ada)
        $oldPhotos = $profile->skill_photos ?? [];
        $allPhotos = array_merge($oldPhotos, $paths);

        $profile->update(['skill_photos' => $allPhotos]);

        return response()->json([
            'success' => true,
            'message' => 'Foto keahlian berhasil diupload',
            'skill_photos' => $allPhotos,
        ]);
    }

public function uploadCertificate(Request $request)
    {
        $request->validate([
            'certificate' => 'required|file|max:2048',
        ]);

        $profile = mitra_profiles::where('user_id', auth()->id())->first();

        if (!$profile) {
            return response()->json(['message' => 'Profil tidak ditemukan'], 404);
        }

        $path = $request->file('certificate')->store('certificates', 'public');
        $profile->update(['certificate' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Sertifikat berhasil diupload',
            'certificate' => $path,
        ]);
    }
}