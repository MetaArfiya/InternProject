<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\mitra_profiles;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use App\Models\users;
use App\Notifications\NewMitraRegistered;

class MitraProfileController extends Controller
{
    // ============================================================
    // UPLOAD KTP (LEGACY — untuk verifikasi awal)
    // ============================================================
    public function uploadKtp(Request $request)
    {
        $request->validate([
            'ktp_file'     => 'required|image|mimes:jpeg,png,jpg|max:2048',
            'certificates' => 'nullable|array',
            'certificates.*' => 'image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $profile = mitra_profiles::where('user_id', auth()->id())->first();

        if (!$profile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil Mitra tidak ditemukan!',
            ], 404);
        }

        // Hapus KTP lama
        if ($profile->verification_image && Storage::disk('public')->exists($profile->verification_image)) {
            Storage::disk('public')->delete($profile->verification_image);
        }

        $ktpPath = $request->file('ktp_file')->store('ktp_berkas', 'public');

        $sertifikatArray = $profile->certificate ?? [];

        if ($request->hasFile('certificates')) {
            if (!empty($sertifikatArray)) {
                foreach ($sertifikatArray as $oldCert) {
                    if (Storage::disk('public')->exists($oldCert)) {
                        Storage::disk('public')->delete($oldCert);
                    }
                }
                $sertifikatArray = [];
            }

            foreach ($request->file('certificates') as $file) {
                $pathCert = $file->store('sertifikat_berkas', 'public');
                $sertifikatArray[] = $pathCert;
            }
        }

        $profile->update([
            'verification_image' => $ktpPath,
            'certificate'        => $sertifikatArray,
        ]);

        // Notifikasi ke semua admin
        $mitra = auth()->user();
        $admins = users::whereHas('roles', function ($query) {
            $query->where('name', 'Admin');
        })->get();

        foreach ($admins as $admin) {
            $admin->notify(new NewMitraRegistered($mitra));
        }

        $certificateUrls = array_map(function ($path) {
            return asset('storage/' . $path);
        }, $sertifikatArray);

        return response()->json([
            'success' => true,
            'message' => 'Berkas KTP dan Sertifikat berhasil diunggah! Menunggu verifikasi harian oleh Admin.',
            'data' => [
                'url_ktp'        => asset('storage/' . $ktpPath),
                'url_sertifikat' => $certificateUrls,
            ],
        ], 200);
    }

    // ============================================================
    // SHOW — Profil publik mitra (untuk halaman detail mitra)
    // ============================================================
    // public function show($id)
    // {
    //     try {
    //         $mitra = users::find($id);

    //         if (!$mitra) {
    //             return response()->json([
    //                 'status'  => 'error',
    //                 'message' => 'Data mitra tidak ditemukan',
    //             ], 404);
    //         }

    //         $profile = mitra_profiles::where('user_id', $mitra->id)->first();

    //         $skillsArray = [];
    //         if ($profile && !empty($profile->skills)) {
    //             $skillsArray = array_map('trim', explode(',', $profile->skills));
    //         }

    //         $ratingVal = $profile && $profile->rating !== null ? (float) $profile->rating : 0.0;
    //         $reviewsCount = 0;
    //         $reviewsList = [];
    //         $satisfactionPercentage = $ratingVal > 0 ? round(($ratingVal / 5.0) * 100) . '%' : '0%';
    //         $jobsCompletedCount = $profile->jobs_completed ?? 0;
    //         $joinedYear = $mitra->created_at ? $mitra->created_at->format('Y') : date('Y');

    //         return response()->json([
    //             'status' => 'success',
    //             'data'   => [
    //                 'id'             => $mitra->id,
    //                 'name'           => $mitra->name ?? 'Mitra',
    //                 'rating'         => $ratingVal,
    //                 'reviews_count'  => $reviewsCount,
    //                 'verified'       => $profile ? ((int) $profile->is_verified === 1) : false,
    //                 'jobs_completed' => $jobsCompletedCount,
    //                 'satisfaction'   => $satisfactionPercentage,
    //                 'joined_year'    => $joinedYear,
    //                 'about'          => $profile->bio ?? 'Belum ada deskripsi profil.',
    //                 'skills'         => !empty($skillsArray) ? $skillsArray : ['Belum ada keahlian'],
    //                 'reviews'        => $reviewsList,
    //             ],
    //         ], 200);

    //     } catch (\Exception $e) {
    //         return response()->json([
    //             'status'  => 'error',
    //             'message' => 'Server Error: ' . $e->getMessage(),
    //         ], 500);
    //     }
    // }

    public function show($id)
    {
        try {
            $mitra = users::find($id);

            if (!$mitra) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Data mitra tidak ditemukan',
                ], 404);
            }

            $profile = mitra_profiles::where('user_id', $mitra->id)->first();

            // =========================================================
            // 1. RATING & REVIEWS — query dari tabel ratings
            // =========================================================
            $reviewsQuery = DB::table('ratings')
                ->where('mitra_id', $mitra->id)
                ->where('is_hidden', 0);

            $reviewsCount = (clone $reviewsQuery)->count();
            $avgRating = (clone $reviewsQuery)->avg('stars');

            $ratingVal = $avgRating !== null
                ? round((float) $avgRating, 1)
                : (float) ($profile->rating ?? 0);

            $satisfactionPercentage = $ratingVal > 0
                ? round(($ratingVal / 5.0) * 100) . '%'
                : '0%';

            // =========================================================
            // 2. SKILLS + FOTO (pair index skill <-> skill_photos)
            // =========================================================
            $skillsRaw = [];
            if ($profile && !empty($profile->skills)) {
                $skillsRaw = array_values(array_filter(
                    array_map('trim', explode(',', $profile->skills))
                ));
            }

            // Decode skill_photos (bisa array atau JSON string)
            $skillPhotosRaw = [];
            if ($profile && !empty($profile->skill_photos)) {
                if (is_array($profile->skill_photos)) {
                    $skillPhotosRaw = $profile->skill_photos;
                } elseif (is_string($profile->skill_photos)) {
                    $decoded = json_decode($profile->skill_photos, true);
                    if (is_array($decoded)) $skillPhotosRaw = $decoded;
                }
            }

            // Gabungkan: skills[i] <-> skill_photos[i]
            $skillsPayload = [];
            $max = max(count($skillsRaw), count($skillPhotosRaw));
            for ($i = 0; $i < $max; $i++) {
                $name  = $skillsRaw[$i] ?? 'Keahlian';
                $photo = $skillPhotosRaw[$i] ?? null;
                $skillsPayload[] = [
                    'name'       => $name,
                    'photo'      => $photo,
                    'photo_url'  => $photo
                        ? url('/api/images/skill_photos/' . basename($photo))
                        : null,
                ];
            }

            // =========================================================
            // 3. CERTIFICATES (bisa string tunggal ATAU array)
            // =========================================================
            $certsRaw = [];
            if ($profile && !empty($profile->certificate)) {
                if (is_array($profile->certificate)) {
                    $certsRaw = $profile->certificate;
                } elseif (is_string($profile->certificate)) {
                    $decoded = json_decode($profile->certificate, true);
                    if (is_array($decoded)) {
                        $certsRaw = $decoded;
                    } else {
                        $certsRaw = [$profile->certificate];
                    }
                }
            }

            $certificatesPayload = array_map(function ($path, $idx) {
                return [
                    'title' => 'Sertifikat ' . ($idx + 1),
                    'file'  => $path,
                    'url'   => url('/api/images/certificates/' . basename($path)),
                ];
            }, $certsRaw, array_keys($certsRaw));

            // =========================================================
            // 4. REVIEWS LIST (opsional, untuk nanti kalau mau tampilkan)
            // =========================================================
            $reviewsList = DB::table('ratings')
                ->leftJoin('users', 'users.id', '=', 'ratings.pelanggan_id')
                ->where('ratings.mitra_id', $mitra->id)
                ->where('ratings.is_hidden', 0)
                ->orderByDesc('ratings.created_at')
                ->limit(10)
                ->get([
                    'ratings.id',
                    'ratings.stars',
                    'ratings.comment',
                    'ratings.created_at',
                    'users.name as reviewer_name',
                ])
                ->map(function ($r) {
                    return [
                        'id'       => $r->id,
                        'stars'    => (int) $r->stars,
                        'comment'  => $r->comment,
                        'date'     => $r->created_at,
                        'reviewer' => $r->reviewer_name ?? 'Pelanggan',
                    ];
                });

            // =========================================================
            // 5. FOTO PROFIL MITRA (dari user.photo_profile)
            // =========================================================
            $profilePhotoUrl = null;
            if (!empty($mitra->photo_profile)) {
                $profilePhotoUrl = url('/api/images/profile/' . basename($mitra->photo_profile));
            }

            // =========================================================
            // RESPONSE
            // =========================================================
            return response()->json([
                'status' => 'success',
                'data'   => [
                    'id'                 => $mitra->id,
                    'name'               => $mitra->name ?? 'Mitra',
                    'profile_photo'      => $mitra->photo_profile,
                    'profile_photo_url'  => $profilePhotoUrl,
                    'rating'             => $ratingVal,
                    'reviews_count'      => $reviewsCount,
                    'verified'           => $profile ? ((int) $profile->is_verified === 1) : false,
                    'jobs_completed'     => $profile->jobs_completed ?? 0,
                    'satisfaction'       => $satisfactionPercentage,
                    'joined_year'        => $mitra->created_at
                                                ? $mitra->created_at->format('Y')
                                                : date('Y'),
                    'about'              => $profile->bio ?? 'Belum ada deskripsi profil.',
                    'skills'             => $skillsPayload,       // array of {name, photo, photo_url}
                    'certificates'       => $certificatesPayload, // array of {title, file, url}
                    'reviews'            => $reviewsList,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Server Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    // ============================================================
    // UPDATE PROFILE — Handle skill, identitas, bank
    // ============================================================
    public function updateProfile(Request $request)
    {
        try {
            $user = auth()->user();
            $profile = mitra_profiles::where('user_id', $user->id)->first();

            if (!$profile) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Profil Mitra tidak ditemukan.',
                ], 404);
            }

            $request->validate([
                'gender'              => 'nullable|string|max:50',
                'birth_date'          => 'nullable|date',
                'city'                => 'nullable|string|max:100',
                'bio'                 => 'nullable|string',
                'skills'              => 'nullable|string|max:255',
                'bank_name'           => 'nullable|string|max:100',
                'bank_account_number' => 'nullable|string|max:50',
                'bank_account_name'   => 'nullable|string|max:100',
            ]);

            $updateData = [];
            $pendingApproval = false;

            // Identitas
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

            // ==========================================================
            // LOGIKA SKILL — WAJIB ACC ADMIN KALAU SUDAH VERIFIED
            // ==========================================================
            if ($request->has('skills')) {
                $newSkills = $request->skills;

                // Kalau verified & skill berubah → pending
                if ($profile->is_verified && $newSkills !== $profile->skills) {

                    // Tolak kalau masih ada pending yang belum di-ACC
                    if (!empty($profile->pending_skills)) {
                        return response()->json([
                            'status'  => 'error',
                            'message' => 'Masih ada pengajuan keahlian yang menunggu ACC admin. Tunggu sampai diproses.',
                        ], 429);
                    }

                    $updateData['pending_skills']        = $newSkills;
                    $updateData['pending_skill_photos']  = [];
                    $updateData['pending_certificate']   = null;
                    $updateData['skills_updated_at']     = now();
                    $pendingApproval = true;

                } else {
                    // Belum verified ATAU skill tidak berubah → langsung update
                    $updateData['skills'] = $newSkills;
                }
            }

            // Rekening bank
            if ($request->has('bank_name')) {
                $updateData['bank_name'] = $request->bank_name;
            }
            if ($request->has('bank_account_number')) {
                $updateData['bank_account_number'] = $request->bank_account_number;
            }
            if ($request->has('bank_account_name')) {
                $updateData['bank_account_name'] = $request->bank_account_name;
            }

            $profile->update($updateData);
            $profile->refresh();

            $message = $pendingApproval
                ? 'Pengajuan perubahan keahlian dikirim. Menunggu persetujuan admin.'
                : 'Profil Mitra berhasil diperbarui.';

            return response()->json([
                'status'  => 'success',
                'message' => $message,
                'pending' => $pendingApproval,
                'data'    => [
                    'gender'               => $profile->gender,
                    'birth_date'           => $profile->birth_date,
                    'city'                 => $profile->city,
                    'bio'                  => $profile->bio,
                    'skills'               => $profile->skills,
                    'pending_skills'       => $profile->pending_skills,
                    'pending_skill_photos' => $profile->pending_skill_photos,
                    'pending_certificate'  => $profile->pending_certificate,
                    'skills_updated_at'    => $profile->skills_updated_at,
                    'bank_name'            => $profile->bank_name,
                    'bank_account_number'  => $profile->bank_account_number,
                    'bank_account_name'    => $profile->bank_account_name,
                    'point'                => $profile->point ?? 0,
                    'rating'               => $profile->rating ?? 0,
                    'is_verified'          => (int) $profile->is_verified === 1,
                ],
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    // ============================================================
    // GET PROFILE — Ambil profil mitra yang sedang login
    // ============================================================
    public function getProfile(Request $request)
    {
        try {
            $user = auth()->user();
            $profile = mitra_profiles::where('user_id', $user->id)->first();

            if (!$profile) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Profil Mitra tidak ditemukan.',
                ], 404);
            }

            $skillsArray = [];
            if (!empty($profile->skills)) {
                $skillsArray = array_values(
                    array_filter(
                        array_map('trim', explode(',', $profile->skills))
                    )
                );
            }

            $reviewsCount = DB::table('ratings')
                ->where('mitra_id', $user->id)
                ->where('is_hidden', 0)
                ->count();

            $avgRating = DB::table('ratings')
                ->where('mitra_id', $user->id)
                ->where('is_hidden', 0)
                ->avg('stars');

            $ratingValue = $avgRating !== null
                ? round((float) $avgRating, 1)
                : (float) ($profile->rating ?? 0);

            return response()->json([
                'status' => 'success',
                'data'   => [
                    'id'       => $user->id,
                    'name'     => $user->name,
                    'email'    => $user->email,
                    'phone'    => $user->phone,
                    'address'  => $user->address,

                    'gender'     => $profile->gender,
                    'birth_date' => $profile->birth_date,
                    'city'       => $profile->city,
                    'bio'        => $profile->bio,
                    'skills'     => $skillsArray,

                    // 🆕 FIELD PENDING UNTUK PERUBAHAN SKILL
                    'pending_skills'       => $profile->pending_skills,
                    'pending_skill_photos' => $profile->pending_skill_photos,
                    'pending_certificate'  => $profile->pending_certificate,
                    'skills_updated_at'    => $profile->skills_updated_at,
                    'skill_admin_note'     => $profile->skill_admin_note,

                    // Rekening bank
                    'bank_name'           => $profile->bank_name,
                    'bank_account_number' => $profile->bank_account_number,
                    'bank_account_name'   => $profile->bank_account_name,

                    // Statistik
                    'point'         => $profile->point ?? 0,
                    'rating'        => $ratingValue,
                    'reviews_count' => $reviewsCount,
                    'is_verified'   => (int) $profile->is_verified === 1,

                    // Berkas
                    'verification_image' => $profile->verification_image,
                    'selfie_image'       => $profile->selfie_image,
                    'certificate'        => $profile->certificate,
                    'skill_photos'       => $profile->skill_photos,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    // ============================================================
    // SUBMIT VERIFICATION — Upload KTP + Selfie untuk verifikasi awal
    // ============================================================
    public function submitVerification(Request $request)
    {
        try {
            $request->validate([
                'ktp_file'    => 'required|image|mimes:jpeg,png,jpg|max:2048',
                'selfie_file' => 'required|image|mimes:jpeg,png,jpg|max:2048',
            ]);

            $user = auth()->user();
            $profile = mitra_profiles::where('user_id', $user->id)->first();

            if (!$profile) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Profil mitra tidak ditemukan.',
                ], 404);
            }

            $ktpPath    = $request->file('ktp_file')->store('profile_photos', 'public');
            $selfiePath = $request->file('selfie_file')->store('profile_photos', 'public');

            $profile->update([
                'verification_image' => $ktpPath,
                'selfie_image'       => $selfiePath,
            ]);

            return response()->json([
                'success'            => true,
                'message'            => 'Verifikasi berhasil dikirim.',
                'verification_image' => $ktpPath,
                'selfie_image'       => $selfiePath,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    // ============================================================
    // UPLOAD SKILL PHOTOS — Handle foto biasa & pending
    // ============================================================
    public function uploadSkillPhotos(Request $request)
    {
        $request->validate([
            'photos.*'   => 'image|max:2048',
            'is_pending' => 'nullable', // Terima string atau boolean
        ]);

        $profile = mitra_profiles::where('user_id', auth()->id())->first();

        if (!$profile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil tidak ditemukan',
            ], 404);
        }

        $paths = [];
        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $photo) {
                $path = $photo->store('skill_photos', 'public');
                $paths[] = $path;
            }
        }

        // Normalisasi is_pending (terima string "true"/"false"/"1"/"0" atau boolean)
        $isPending = in_array(
            $request->input('is_pending'),
            ['true', true, '1', 1],
            true
        );

        // =========================================================
        // KALAU PENDING → simpan ke pending_skill_photos
        // =========================================================
        if ($isPending && $profile->is_verified) {
            $oldPending = $profile->pending_skill_photos ?? [];
            $allPending = array_merge($oldPending, $paths);

            $profile->update(['pending_skill_photos' => $allPending]);

            return response()->json([
                'success'              => true,
                'message'              => 'Foto keahlian baru ditambahkan (menunggu ACC admin).',
                'pending_skill_photos' => $allPending,
                'is_pending'           => true,
            ], 200);
        }

        // =========================================================
        // KALAU BUKAN PENDING → simpan ke skill_photos (langsung aktif)
        // =========================================================
        $oldPhotos = $profile->skill_photos ?? [];
        $allPhotos = array_merge($oldPhotos, $paths);

        $profile->update(['skill_photos' => $allPhotos]);

        return response()->json([
            'success'      => true,
            'message'      => 'Foto keahlian berhasil diupload',
            'skill_photos' => $allPhotos,
            'is_pending'   => false,
        ], 200);
    }

    // ============================================================
    // UPLOAD CERTIFICATE — Handle sertifikat biasa & pending
    // ============================================================
    public function uploadCertificate(Request $request)
    {
        $request->validate([
            'certificate' => 'required|file|max:2048',
            'is_pending'  => 'nullable', // Terima string atau boolean
        ]);

        $profile = mitra_profiles::where('user_id', auth()->id())->first();

        if (!$profile) {
            return response()->json([
                'success' => false,
                'message' => 'Profil tidak ditemukan',
            ], 404);
        }

        $path = $request->file('certificate')->store('certificates', 'public');

        // Normalisasi is_pending
        $isPending = in_array(
            $request->input('is_pending'),
            ['true', true, '1', 1],
            true
        );

        // =========================================================
        // KALAU PENDING → simpan ke pending_certificate
        // =========================================================
        if ($isPending && $profile->is_verified) {
            $profile->update(['pending_certificate' => $path]);

            return response()->json([
                'success'             => true,
                'message'             => 'Sertifikat baru diupload (menunggu ACC admin).',
                'pending_certificate' => $path,
                'is_pending'          => true,
            ], 200);
        }

        // =========================================================
        // KALAU BUKAN PENDING → simpan ke certificate (langsung aktif)
        // =========================================================
        $profile->update(['certificate' => $path]);

        return response()->json([
            'success'     => true,
            'message'     => 'Sertifikat berhasil diupload',
            'certificate' => $path,
            'is_pending'  => false,
        ], 200);
    }

    // ============================================================
    // ADMIN — LIST SEMUA MITRA YANG MENGAJUKAN PERUBAHAN SKILL
    // ============================================================
    public function pendingSkills(Request $request)
    {
        try {
            $list = mitra_profiles::whereNotNull('pending_skills')
                ->where('pending_skills', '!=', '')
                ->with('user:id,name,email,phone,photo_profile')
                ->orderBy('skills_updated_at', 'desc')
                ->get()
                ->map(function ($profile) {
                    // Decode skill_photos
                    $skillPhotos = [];
                    if (is_array($profile->skill_photos)) {
                        $skillPhotos = $profile->skill_photos;
                    } elseif (is_string($profile->skill_photos) && !empty($profile->skill_photos)) {
                        $decoded = json_decode($profile->skill_photos, true);
                        if (is_array($decoded)) $skillPhotos = $decoded;
                    }

                    // Decode pending_skill_photos
                    $pendingPhotos = [];
                    if (is_array($profile->pending_skill_photos)) {
                        $pendingPhotos = $profile->pending_skill_photos;
                    } elseif (is_string($profile->pending_skill_photos) && !empty($profile->pending_skill_photos)) {
                        $decoded = json_decode($profile->pending_skill_photos, true);
                        if (is_array($decoded)) $pendingPhotos = $decoded;
                    }

                    return [
                        'id'                   => $profile->id,
                        'user_id'              => $profile->user_id,
                        'name'                 => $profile->user->name ?? 'Tanpa Nama',
                        'email'                => $profile->user->email ?? '-',
                        'phone'                => $profile->user->phone ?? '-',
                        'profile_photo'        => $profile->user->photo_profile ?? null,
                        'current_skills'       => $profile->skills,
                        'pending_skills'       => $profile->pending_skills,
                        'skills_updated_at'    => $profile->skills_updated_at,
                        'skill_photos'         => $skillPhotos,
                        'pending_skill_photos' => $pendingPhotos,
                        'certificate'          => $profile->certificate,
                        'pending_certificate'  => $profile->pending_certificate,
                        'rating'               => $profile->rating ?? 0,
                        'point'                => $profile->point ?? 0,
                        'jobs_completed'       => $profile->jobs_completed ?? 0,
                    ];
                });

            return response()->json([
                'success' => true,
                'total'   => $list->count(),
                'data'    => $list,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    // ============================================================
    // ADMIN APPROVE SKILL
    // ============================================================
    public function approveSkill(Request $request, $mitraId)
    {
        try {
            $profile = mitra_profiles::where('user_id', $mitraId)->first();

            if (!$profile) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Profil mitra tidak ditemukan.',
                ], 404);
            }

            if (empty($profile->pending_skills)) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Tidak ada pengajuan keahlian untuk mitra ini.',
                ], 400);
            }

            // Pindahkan foto pending ke aktif
            $pendingPhotos = $profile->pending_skill_photos ?? [];
            $newPhotos = !empty($pendingPhotos)
                ? $pendingPhotos
                : ($profile->skill_photos ?? []);

            // Pindahkan sertifikat pending ke aktif
            $newCertificate = !empty($profile->pending_certificate)
                ? $profile->pending_certificate
                : $profile->certificate;

            $profile->update([
                'skills'               => $profile->pending_skills,
                'skill_photos'         => $newPhotos,
                'certificate'          => $newCertificate,
                'pending_skills'       => null,
                'pending_skill_photos' => null,
                'pending_certificate'  => null,
                'skill_admin_note'     => $request->note ?? null,
                'skills_updated_at'    => now(),
            ]);

            return response()->json([
                'status'  => 'success',
                'message' => 'Keahlian mitra berhasil disetujui.',
                'data'    => [
                    'user_id' => $mitraId,
                    'skills'  => $profile->skills,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    // ============================================================
    // ADMIN REJECT SKILL
    // ============================================================
    public function rejectSkill(Request $request, $mitraId)
    {
        try {
            $profile = mitra_profiles::where('user_id', $mitraId)->first();

            if (!$profile) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Profil mitra tidak ditemukan.',
                ], 404);
            }

            if (empty($profile->pending_skills)) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Tidak ada pengajuan keahlian untuk mitra ini.',
                ], 400);
            }

            $profile->update([
                'pending_skills'       => null,
                'pending_skill_photos' => null,
                'pending_certificate'  => null,
                'skill_admin_note'     => $request->note ?? 'Ditolak oleh admin.',
                'skills_updated_at'    => now(),
            ]);

            return response()->json([
                'status'  => 'success',
                'message' => 'Pengajuan keahlian ditolak.',
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}