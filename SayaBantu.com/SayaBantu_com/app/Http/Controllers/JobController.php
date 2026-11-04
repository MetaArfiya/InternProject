<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Carbon;

use App\Models\jobs;
use App\Models\job_bids;
use App\Models\mitra_profiles;
use App\Models\users;
use App\Models\Payment;
use App\Models\Wallet;
use App\Models\Rating;
use App\Models\system_setting;
use App\Models\City;

use App\Providers\WalletService;
use App\Notifications\BidAccepted;
use App\Helpers\ActivityLogger;

class JobController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | HELPER
    |--------------------------------------------------------------------------
    */

    private function logActivity(
        $userId,
        string $title,
        string $description,
        string $icon,
        string $role
    ): void {
        try {
            ActivityLogger::log(
                $userId,
                $title,
                $description,
                $icon,
                $role
            );
        } catch (\Throwable $e) {
            Log::warning('ActivityLogger gagal: ' . $e->getMessage());
        }
    }

    private function generateJobCode($id): string
    {
        return '#JOB-' . str_pad((string) $id, 4, '0', STR_PAD_LEFT);
    }

    /**
     * Memastikan jadwal mulai dan selesai valid.
     */
    private function calculateScheduleEnd(
        string $startAt,
        int $durationMinutes
    ): array {
        // Datetime columns do not store timezone information. Persist values
        // in the app timezone so Eloquent's Asia/Jakarta casts read them back
        // without shifting the user's selected wall-clock time.
        $start = Carbon::parse($startAt)
            ->setTimezone(config('app.timezone', 'Asia/Jakarta'));
        $end = $start->copy()->addMinutes($durationMinutes);

        return [
            'start' => $start,
            'end' => $end,
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | DETAIL PEKERJAAN
    |--------------------------------------------------------------------------
    */

    public function show($id)
    {
        try {
            $job = jobs::withCount('bids')
                ->with([
                    'bids' => fn($query) => $query->latest(),
                    'bids.mitraProfile',
                    'bids.user',
                ])
                ->where('pelanggan_id', auth()->id())
                ->find($id);

            if (!$job) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pekerjaan tidak ditemukan.',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Detail pekerjaan berhasil diambil.',
                'data' => $job,
            ]);
        } catch (\Throwable $e) {
            Log::error('JobController@show: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | SEARCH PEKERJAAN
    |--------------------------------------------------------------------------
    */

    public function search(Request $request)
    {
        $validated = $request->validate([
            'keyword' => ['nullable', 'string', 'max:100'],
        ]);

        try {
            $keyword = trim((string) ($validated['keyword'] ?? ''));

            $query = jobs::where('status', 'Mencari Mitra');

            if ($keyword !== '') {
                $query->where(function ($q) use ($keyword) {
                    $q->where('tittle', 'LIKE', "%{$keyword}%")
                        ->orWhere('description', 'LIKE', "%{$keyword}%");
                });
            }

            return response()->json([
                'success' => true,
                'message' => $keyword !== ''
                    ? 'Hasil pencarian untuk: "' . $keyword . '"'
                    : 'Menampilkan semua lowongan aktif.',
                // Bound public search responses to avoid unbounded queries and payloads.
                'data' => $query->latest()
                    ->limit(50)
                    ->get([
                        'id',
                        'tittle',
                        'category',
                        'description',
                        'location',
                        'initial_budget',
                        'status',
                        'created_at',
                    ])
                    ->map(function ($job) {
                        // Public previews must not disclose customer details or exact addresses.
                        $job->description = 'Daftar untuk melihat detail pekerjaan.';
                        $job->location = 'Lokasi tersedia setelah mendaftar';

                        return $job;
                    }),
            ]);
        } catch (\Throwable $e) {
            Log::error('JobController@search: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mencari pekerjaan.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | PEKERJAAN MILIK PELANGGAN
    |--------------------------------------------------------------------------
    */

    public function myJobs()
    {
        try {
            $pelangganId = auth()->id();

            $jobList = jobs::withCount('bids')
                ->with([
                    'mitra:id,name',
                    'pelanggan:id,name',
                ])
                ->where('pelanggan_id', $pelangganId)
                ->latest()
                ->get();

            $myRatings = Rating::where('pelanggan_id', $pelangganId)
                ->pluck('stars', 'job_id');

            $payments = Payment::whereIn('job_id', $jobList->pluck('id'))
                ->get()
                ->keyBy('job_id');

            $jobsTransformed = $jobList->map(function ($job) use (
                $myRatings,
                $payments
            ) {
                $data = $job->toArray();

                $hasRated = $myRatings->has($job->id);
                $payment = $payments->get($job->id);

                $data['has_rated'] = $hasRated;
                $data['my_rating'] = $hasRated
                    ? $myRatings->get($job->id)
                    : null;

                $data['can_rate'] = (
                    $job->status === 'Selesai' && !$hasRated
                );

                $data['payment_status'] = $payment->status ?? null;
                $data['payment_id'] = $payment->id ?? null;

                return $data;
            });

            return response()->json([
                'success' => true,
                'message' => 'Berhasil mengambil riwayat pekerjaan kamu.',
                'statistics' => [
                    'total_posting' => $jobList->count(),

                    'terjadwal' => $jobList
                        ->where('status', 'Terjadwal')
                        ->count(),

                    'sedang_berjalan' => $jobList
                        ->where('status', 'Sedang Dikerjakan')
                        ->count(),

                    'selesai' => $jobList
                        ->where('status', 'Selesai')
                        ->count(),
                ],
                'data' => $jobsTransformed,
            ]);
        } catch (\Throwable $e) {
            Log::error('JobController@myJobs: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | PELANGGAN MEMBUAT PEKERJAAN
    |--------------------------------------------------------------------------
    */

    public function store(Request $request)
    {
        $validated = $request->validate([
            'tittle' => 'required|string|max:255',
            'description' => 'required|string',
            'location' => 'required|string',
            'address_detail' => 'nullable|string',

            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',

            'location_lat' => 'nullable|numeric|between:-90,90',
            'location_lng' => 'nullable|numeric|between:-180,180',

            'city_name' => 'required|string|max:255',
            'category' => 'nullable|string|max:255',

            'initial_budget' => 'required|numeric|min:10000',
            'duration' => 'required|string|max:50',

            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
            'pin' => 'required|string|size:6',

            'preferred_start_at' => 'required|date|after:now',
        ]);

        $user = auth()->user();
        $budget = (float) $validated['initial_budget'];

        $cityName = mb_strtolower(trim($validated['city_name']));

        $city = City::whereRaw(
            'LOWER(name) = ?',
            [$cityName]
        )->first();

        if (!$city) {
            return response()->json([
                'success' => false,
                'message' => 'Kota atau kabupaten lokasi pekerjaan tidak ditemukan dalam database.',
            ], 422);
        }

        $jobLatitude = $validated['location_lat']
            ?? $validated['latitude']
            ?? null;

        $jobLongitude = $validated['location_lng']
            ?? $validated['longitude']
            ?? null;

        if (
            !$user->pin ||
            !Hash::check($validated['pin'], $user->pin)
        ) {
            return response()->json([
                'success' => false,
                'message' => 'PIN yang Anda masukkan salah.',
            ], 400);
        }

        $wallet = Wallet::where('user_id', $user->id)->first();

        if (!$wallet || (float) $wallet->balance < $budget) {
            return response()->json([
                'success' => false,
                'message' => 'Saldo tidak mencukupi. Silakan Topup terlebih dahulu.',
            ], 400);
        }

        $imagePath = null;
        $imageUrl = null;

        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')
                ->store('jobs', 'public');

            $imageUrl = '/storage/' . $imagePath;
        }

        try {
            $job = DB::transaction(function () use (
                $user,
                $validated,
                $budget,
                $city,
                $jobLatitude,
                $jobLongitude,
                $imageUrl
            ) {
                $wallet = Wallet::where('user_id', $user->id)
                    ->lockForUpdate()
                    ->first();

                if (!$wallet || (float) $wallet->balance < $budget) {
                    throw new \RuntimeException(
                        'Saldo tidak mencukupi. Silakan Topup terlebih dahulu.'
                    );
                }

                $job = jobs::create([
                    'pelanggan_id' => $user->id,
                    'city_id' => $city->id,

                    'tittle' => $validated['tittle'],
                    'description' => $validated['description'],
                    'location' => $validated['location'],

                    'location_description' =>
                    $validated['address_detail'] ?? null,

                    'location_lat' => $jobLatitude,
                    'location_lng' => $jobLongitude,

                    'category' => $validated['category'] ?? null,
                    'initial_budget' => $budget,
                    'duration' => $validated['duration'],
                    'image_url' => $imageUrl,

                    'ai_recommended_budget' => $this->buildRecommendation(
                        $validated['tittle'],
                        $validated['description']
                    ),

                    'preferred_start_at' => Carbon::parse(
                        $validated['preferred_start_at']
                    )->setTimezone(config('app.timezone', 'Asia/Jakarta')),

                    'status' => 'Mencari Mitra',
                ]);

                $payment = Payment::create([
                    'job_id' => $job->id,
                    'pelanggan_id' => $user->id,

                    'job_amount' => $budget,
                    'total_paid' => $budget,

                    'status' => 'held',
                    'held_at' => now(),

                    'reference_code' => 'PAY-' . strtoupper(uniqid()),
                ]);

                app(WalletService::class)->hold(
                    (int) $user->id,
                    $budget,
                    (int) $payment->id
                );

                return $job;
            });

            $this->logActivity(
                $user->id,
                'Membuat Job Baru',
                'Job "' . $job->tittle .
                    '" dibuat dan saldo ditahan sebesar Rp ' .
                    number_format($budget, 0, ',', '.') . '.',
                'post_add',
                'Pelanggan'
            );

            return response()->json([
                'success' => true,
                'message' => 'Lowongan berhasil diposting! Saldo Anda telah ditahan.',
                'data' => $job,
            ], 201);
        } catch (\RuntimeException $e) {
            if ($imagePath) {
                Storage::disk('public')->delete($imagePath);
            }

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            if ($imagePath) {
                Storage::disk('public')->delete($imagePath);
            }

            Log::error('JobController@store: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat pekerjaan.',
            ], 500);
        }
    }

    public function updateByCustomer(Request $request, $id)
    {
        $validated = $request->validate([
            'initial_budget' => 'required|numeric|min:10000',
            'pin' => 'nullable|string|size:6',
        ]);

        if (empty($validated)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada perubahan pekerjaan yang dikirim.',
            ], 422);
        }

        try {
            $customerId = (int) auth()->id();

            $job = DB::transaction(function () use (
                $id,
                $customerId,
                $validated
            ) {
                $job = jobs::whereKey($id)->lockForUpdate()->first();

                if (!$job || (int) $job->pelanggan_id !== $customerId) {
                    throw new \RuntimeException(
                        'Pekerjaan tidak ditemukan atau bukan milik Anda.'
                    );
                }

                if ($job->status !== 'Mencari Mitra' || $job->mitra_id !== null) {
                    throw new \RuntimeException(
                        'Pekerjaan hanya dapat diedit sebelum diambil Mitra.'
                    );
                }

                $payment = Payment::where('job_id', $job->id)
                    ->lockForUpdate()
                    ->first();

                if (!$payment || $payment->status !== 'held') {
                    throw new \RuntimeException(
                        'Dana pekerjaan tidak tersedia untuk diperbarui.'
                    );
                }

                $newBudget = round((float) $validated['initial_budget'], 2);
                $oldBudget = (float) $payment->total_paid;
                $difference = round($newBudget - $oldBudget, 2);

                if ($difference > 0) {
                    $customer = users::find($customerId);
                    if (
                        !$customer ||
                        !$customer->pin ||
                        empty($validated['pin']) ||
                        !Hash::check($validated['pin'], $customer->pin)
                    ) {
                        throw new \RuntimeException(
                            'PIN diperlukan dan harus benar untuk menambah nominal pekerjaan.'
                        );
                    }

                    app(WalletService::class)->hold(
                        $customerId,
                        $difference,
                        (int) $payment->id
                    );
                } elseif ($difference < 0) {
                    app(WalletService::class)->refundHold(
                        $customerId,
                        abs($difference),
                        (int) $payment->id
                    );
                }

                $payment->update([
                    'job_amount' => $newBudget,
                    'total_paid' => $newBudget,
                ]);
                $job->initial_budget = $newBudget;

                $job->save();

                return $job->fresh();
            }, 3);

            $this->logActivity(
                $customerId,
                'Pelanggan mengubah nominal pekerjaan',
                'Pelanggan memperbarui nominal pekerjaan "' . $job->tittle . '" menjadi Rp ' .
                    number_format((float) $job->initial_budget, 0, ',', '.') . '.',
                'edit',
                'Pelanggan'
            );

            return response()->json([
                'success' => true,
                'message' => 'Pekerjaan berhasil diperbarui.',
                'data' => $job,
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            Log::error('JobController@updateByCustomer: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui pekerjaan.',
            ], 500);
        }
    }

    private function buildRecommendation(
        string $title,
        string $description
    ): string {
        $judul = mb_strtolower($title);
        $deskripsi = mb_strtolower($description);

        $minPrice = 75000;
        $maxPrice = 150000;

        $recommendation =
            'Analisis Sistem: Deteksi jenis jasa harian / personal umum.';

        if (
            str_contains($deskripsi, 'ac') ||
            str_contains($judul, 'ac')
        ) {
            $minPrice = 75000;
            $maxPrice = 180000;

            $recommendation =
                'Analisis Sistem: Deteksi perawatan / cuci AC ringan.';

            if (
                str_contains($deskripsi, 'bocor') ||
                str_contains($deskripsi, 'freon')
            ) {
                $minPrice = 200000;
                $maxPrice = 400000;

                $recommendation =
                    'Analisis Sistem: Deteksi perbaikan AC bocor + tambah Freon.';
            }
        }

        return $recommendation .
            ' Kisaran harga pasar: Rp ' .
            number_format($minPrice, 0, ',', '.') .
            ' - Rp ' .
            number_format($maxPrice, 0, ',', '.') . '.';
    }

    /*
    |--------------------------------------------------------------------------
    | DAFTAR PEKERJAAN UNTUK MITRA
    |--------------------------------------------------------------------------
    */

    public function availableJobs(Request $request)
    {
        try {
            $mitraId = auth()->id();

            $mitraProfile = mitra_profiles::where(
                'user_id',
                $mitraId
            )->first();

            if (!$mitraProfile) {
                return response()->json([
                    'success' => true,
                    'message' => 'Profile Mitra tidak ditemukan.',
                    'active_offers_count' => 0,
                    'user_points' => 0,
                    'data' => [],
                    'jobs' => [],
                ]);
            }

            $lat = $request->query('lat');
            $lng = $request->query('lng');

            $radius = max(
                1,
                min(50, (float) $request->query('radius', 5))
            );

            $hasLocation = (
                $lat !== null &&
                $lng !== null &&
                is_numeric($lat) &&
                is_numeric($lng)
            );

            if ($hasLocation) {
                $lat = (float) $lat;
                $lng = (float) $lng;

                if (
                    $lat < -90 ||
                    $lat > 90 ||
                    $lng < -180 ||
                    $lng > 180
                ) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Koordinat lokasi tidak valid.',
                    ], 422);
                }
            }

            $rawSkills = !empty($mitraProfile->skills)
                ? $mitraProfile->skills
                : ($mitraProfile->category ?? '');

            $mitraSkills = [];

            if (!empty($rawSkills)) {
                $mitraSkills = array_unique(
                    array_filter(
                        array_map(
                            fn($skill) => mb_strtolower(trim($skill)),
                            explode(',', $rawSkills)
                        )
                    )
                );
            }

            $query = jobs::withCount('bids')
                ->where('status', 'Mencari Mitra');

            if (!empty($mitraSkills)) {
                $query->where(function ($q) use ($mitraSkills) {
                    foreach ($mitraSkills as $skill) {
                        $q->orWhereRaw(
                            'LOWER(TRIM(category)) = ?',
                            [$skill]
                        );
                    }
                });
            } else {
                $query->whereRaw('1 = 0');
            }

            $query->whereDoesntHave('bids', function ($q) use ($mitraId) {
                $q->where('mitra_id', $mitraId);
            });

            if ($hasLocation) {
                $haversine = '
                    (
                        6371 * ACOS(
                            LEAST(1, GREATEST(-1,
                                COS(RADIANS(?)) *
                                COS(RADIANS(location_lat)) *
                                COS(RADIANS(location_lng) - RADIANS(?)) +
                                SIN(RADIANS(?)) *
                                SIN(RADIANS(location_lat))
                            ))
                        )
                    )
                ';

                $query->whereNotNull('location_lat')
                    ->whereNotNull('location_lng')
                    ->selectRaw(
                        "jobs.*, {$haversine} AS distance_km",
                        [$lat, $lng, $lat]
                    )
                    ->havingRaw('distance_km <= ?', [$radius])
                    ->orderBy('distance_km');
            } else {
                $query->latest();
            }

            $jobList = $query->get();

            $jobsTransformed = $jobList->map(function ($job) {
                $data = $job->toArray();

                $data['distance_km'] = isset($job->distance_km)
                    ? round((float) $job->distance_km, 2)
                    : null;

                $data['job_code'] = $this->generateJobCode($job->id);

                return $data;
            });

            $activeOffersCount = job_bids::where('mitra_id', $mitraId)
                ->whereIn('status', [
                    'Menunggu',
                    'Diterima Pelanggan',
                ])
                ->count();

            return response()->json([
                'success' => true,

                'message' => $hasLocation
                    ? "Berhasil mengambil pekerjaan dalam radius {$radius} km."
                    : 'Berhasil mengambil daftar pekerjaan sesuai kemampuan Mitra.',

                'mitra_skills' => array_values($mitraSkills),
                'active_offers_count' => $activeOffersCount,
                'user_points' => $mitraProfile->point ?? 0,

                'meta' => [
                    'radius_km' => $hasLocation ? $radius : null,
                    'mitra_lat' => $hasLocation ? $lat : null,
                    'mitra_lng' => $hasLocation ? $lng : null,
                    'using_radius' => $hasLocation,
                    'total' => $jobsTransformed->count(),
                ],

                'data' => $jobsTransformed,
                'jobs' => $jobsTransformed,
            ]);
        } catch (\Throwable $e) {
            Log::error('JobController@availableJobs: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil daftar pekerjaan.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | PENAWARAN MILIK MITRA
    |--------------------------------------------------------------------------
    */

    public function myOffers(Request $request)
    {
        try {
            $userId = auth()->id();

            $profile = mitra_profiles::where(
                'user_id',
                $userId
            )->first();

            $totalMitra = mitra_profiles::count();

            $higherPointsCount = mitra_profiles::where(
                'point',
                '>',
                $profile ? $profile->point : 0
            )->count();

            $ranking = $higherPointsCount + 1;

            $myBids = job_bids::where('mitra_id', $userId)
                ->whereIn('status', [
                    'Menunggu',
                    'Diterima Pelanggan',
                ])
                ->with('job')
                ->get();

            $myBids = $myBids->sortBy(function ($bid) {
                $jobStatus = $bid->job?->status ?? 'Menunggu';

                $priority = in_array($jobStatus, [
                    'Terjadwal',
                    'Sedang Dikerjakan',
                    'Menunggu Konfirmasi Selesai',
                    'Mencari Mitra',
                ]) ? 1 : 2;

                return $priority . '-' . $bid->created_at->timestamp;
            })->values();

            $formattedOffers = $myBids->map(function ($bid) {
                $job = $bid->job;

                $queuePosition = job_bids::where('job_id', $bid->job_id)
                    ->where('status', 'Menunggu')
                    ->where('id', '<=', $bid->id)
                    ->count();

                $jobStatus = $job?->status ?? $bid->status;

                return [
                    'id' => $bid->id,
                    'job_id' => $bid->job_id,

                    'tittle' => $job?->tittle
                        ?? 'Pekerjaan Tidak Diketahui',

                    'price' => (float) ($bid->offered_price ?? 0),

                    'proposed_start_at' => $bid->proposed_start_at,
                    'estimated_duration_minutes' =>
                    $bid->estimated_duration_minutes,

                    'scheduled_start_at' => $job?->scheduled_start_at,
                    'scheduled_end_at' => $job?->scheduled_end_at,

                    'queue_position' => $jobStatus === 'Terjadwal'
                        ? 1
                        : ($queuePosition ?: 1),

                    'bid_status' => $bid->status,

                    'is_top' => (
                        $jobStatus === 'Terjadwal' ||
                        $queuePosition === 1
                    ),

                    'status' => $jobStatus,

                    'completion_photo_url' => $job?->completion_photo_url,
                    'completion_status' => $job?->completion_status,

                    'is_verified' => (bool) ($job?->is_verified ?? false),

                    'proof_image' => $job?->completion_photo_url,

                    'proof_submitted' => !empty($job?->completion_photo_url),

                    'can_submit_proof' => (
                        $jobStatus === 'Sedang Dikerjakan'
                    ),

                    'proof_description' => $job?->completion_admin_note,

                    'started_at' => $job?->started_at,
                    'completed_at' => $job?->completed_at,

                    'completion_submitted_at' =>
                    $job?->completion_submitted_at,

                    'completion_verified_at' =>
                    $job?->completion_verified_at,
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Berhasil mengambil daftar penawaran aktif.',

                'sidebar' => [
                    'nama_mitra' => auth()->user()->name ?? 'Mitra',
                    'total_poin' => $profile?->point ?? 0,
                    'peringkat' => "Peringkat ke-{$ranking} dari {$totalMitra} mitra",

                    'is_verified' => $profile
                        ? (bool) $profile->is_verified
                        : false,
                ],

                'data' => $formattedOffers,
            ]);
        } catch (\Throwable $e) {
            Log::error('JobController@myOffers: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil daftar penawaran.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | MITRA MENERIMA PEKERJAAN PELANGGAN
    |--------------------------------------------------------------------------
    */

    public function applyJob(Request $request, $id)
    {
        $validated = $request->validate([
            'expected_initial_budget' => 'required|numeric|min:10000',
            'expected_tittle' => 'required|string|max:255',
            'expected_description' => 'required|string',
        ]);

        try {
            $mitraId = (int) auth()->id();
            $mitraProfile = mitra_profiles::where('user_id', $mitraId)->first();

            if (!$mitraProfile || !$mitraProfile->is_verified) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akun anda belum diverifikasi oleh Admin.',
                ], 403);
            }

            $result = DB::transaction(function () use (
                $id,
                $mitraId,
                $mitraProfile,
                $validated
            ) {
                $job = jobs::whereKey($id)->lockForUpdate()->first();

                if (!$job || $job->status !== 'Mencari Mitra') {
                    throw new \RuntimeException(
                        'Pekerjaan ini sudah diambil Mitra lain atau tidak tersedia.'
                    );
                }

                if (
                    round((float) $job->initial_budget, 2) !==
                        round((float) $validated['expected_initial_budget'], 2) ||
                    $job->tittle !== $validated['expected_tittle'] ||
                    $job->description !== $validated['expected_description']
                ) {
                    throw new \RuntimeException(
                        'Pelanggan memperbarui pekerjaan. Muat ulang daftar pekerjaan sebelum mengambilnya.'
                    );
                }

                if (empty($job->preferred_start_at)) {
                    throw new \RuntimeException(
                        'Jadwal mulai dari pelanggan belum tersedia.'
                    );
                }

                $durationLabel = mb_strtolower(trim((string) $job->duration));
                $durationLabel = str_replace(['–', '—'], '-', $durationLabel);
                $durationMinutes = match ($durationLabel) {
                    '1-2 jam' => 120,
                    '3-5 jam' => 300,
                    '1 hari' => 1440,
                    '2-3 hari' => 4320,
                    '1 minggu' => 10080,
                    '> 1 minggu', 'lebih dari 1 minggu' => 20160,
                    default => 0,
                };

                if ($durationMinutes <= 0) {
                    throw new \RuntimeException(
                        'Durasi pekerjaan pelanggan tidak dikenali.'
                    );
                }

                $schedule = $this->calculateScheduleEnd(
                    (string) $job->preferred_start_at,
                    $durationMinutes
                );
                $scheduleStart = $schedule['start'];
                $scheduleEnd = $schedule['end'];

                if ($scheduleStart->lessThanOrEqualTo(now())) {
                    throw new \RuntimeException(
                        'Jadwal pekerjaan sudah lewat dan tidak dapat diterima.'
                    );
                }

                $conflictingJob = jobs::where('mitra_id', $mitraId)
                    ->whereIn('status', [
                        'Terjadwal',
                        'Sedang Dikerjakan',
                        'Menunggu Konfirmasi Selesai',
                    ])
                    ->whereNotNull('scheduled_start_at')
                    ->whereNotNull('scheduled_end_at')
                    ->where('scheduled_start_at', '<', $scheduleEnd)
                    ->where('scheduled_end_at', '>', $scheduleStart)
                    ->lockForUpdate()
                    ->first();

                if ($conflictingJob) {
                    throw new \RuntimeException(
                        'Jadwal pekerjaan berbenturan dengan pekerjaan Anda yang lain.'
                    );
                }

                $payment = Payment::where('job_id', $job->id)
                    ->lockForUpdate()
                    ->first();
                if (!$payment || $payment->status !== 'held') {
                    throw new \RuntimeException(
                        'Dana escrow pelanggan tidak tersedia untuk pekerjaan ini.'
                    );
                }

                $price = (float) $job->initial_budget;
                if ($price <= 0) {
                    throw new \RuntimeException(
                        'Harga yang ditetapkan pelanggan tidak valid.'
                    );
                }

                $settings = system_setting::first();
                $commissionPercent = $settings
                    ? (float) $settings->platform_commission_percent
                    : 15.00;
                $commissionAmount = round($price * ($commissionPercent / 100), 2);
                $mitraEarning = round($price - $commissionAmount, 2);

                $bid = job_bids::create([
                    'job_id' => $job->id,
                    'mitra_id' => $mitraId,
                    'offered_price' => $price,
                    'mitras_point_at_time' => $mitraProfile->point ?? 0,
                    // Nilai ini dipertahankan agar data lama dan daftar aktif tetap kompatibel.
                    'status' => 'Diterima Pelanggan',
                    'proposed_start_at' => $scheduleStart,
                    'estimated_duration_minutes' => $durationMinutes,
                ]);

                $job->update([
                    'mitra_id' => $mitraId,
                    'final_price' => $price,
                    'scheduled_start_at' => $scheduleStart,
                    'scheduled_end_at' => $scheduleEnd,
                    'started_at' => null,
                    'status' => 'Terjadwal',
                ]);

                $payment->update([
                    'mitra_id' => $mitraId,
                    'job_amount' => $price,
                    'commission_percent' => $commissionPercent,
                    'commission_amount' => $commissionAmount,
                    'mitra_earning' => $mitraEarning,
                    'total_paid' => $price,
                ]);

                return [
                    'job' => $job->fresh(),
                    'bid' => $bid,
                ];
            }, 3);

            $customer = users::find($result['job']->pelanggan_id);
            if ($customer) {
                try {
                    $customer->notify(new \App\Notifications\PartnerAcceptedJob(
                        $result['job'],
                        $result['bid']
                    ));
                } catch (\Throwable $notificationException) {
                    Log::warning(
                        'Notifikasi mitra menerima pekerjaan gagal: ' .
                            $notificationException->getMessage()
                    );
                }
            }

            $this->logActivity(
                $mitraId,
                'Mitra menerima pekerjaan',
                'Mitra menerima pekerjaan "' . $result['job']->tittle .
                    '" dengan harga pelanggan Rp ' .
                    number_format((float) $result['job']->final_price, 0, ',', '.') . '.',
                'check_circle',
                'Mitra'
            );

            return response()->json([
                'success' => true,
                'message' => 'Pekerjaan berhasil diterima. Anda menjadi Mitra pertama yang menyetujuinya.',
                'data' => $result['job'],
            ], 200);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            Log::error('JobController@applyJob: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal menerima pekerjaan.',
            ], 500);
        }
    }
    /*
    |--------------------------------------------------------------------------
    | PELANGGAN MENOLAK PENAWARAN
    |--------------------------------------------------------------------------
    */

    public function rejectBid($bidId)
    {
        try {
            $pelangganId = auth()->id();

            $result = DB::transaction(function () use (
                $bidId,
                $pelangganId
            ) {
                $bid = job_bids::whereKey($bidId)
                    ->lockForUpdate()
                    ->first();

                if (!$bid) {
                    throw new \RuntimeException(
                        'Penawaran tidak ditemukan.'
                    );
                }

                $job = jobs::whereKey($bid->job_id)
                    ->lockForUpdate()
                    ->first();

                if (
                    !$job ||
                    (int) $job->pelanggan_id !== (int) $pelangganId
                ) {
                    throw new \RuntimeException(
                        'Kamu tidak memiliki akses ke penawaran ini.'
                    );
                }

                if ($job->status !== 'Mencari Mitra') {
                    throw new \RuntimeException(
                        'Penawaran tidak dapat ditolak karena pekerjaan sudah diproses.'
                    );
                }

                if ($bid->status !== 'Menunggu') {
                    throw new \RuntimeException(
                        'Penawaran ini sudah tidak berstatus menunggu.'
                    );
                }

                $bid->update([
                    'status' => 'Ditolak',
                ]);

                return [
                    'bid' => $bid->fresh(),
                    'job' => $job,
                ];
            });

            $this->logActivity(
                $pelangganId,
                'Pelanggan menolak penawaran',
                'Pelanggan menolak penawaran untuk "' .
                    $result['job']->tittle . '".',
                'cancel',
                'Pelanggan'
            );

            return response()->json([
                'success' => true,
                'message' => 'Penawaran berhasil ditolak. Kamu masih bisa memilih penawaran Mitra lainnya.',
                'data' => $result['bid'],
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            Log::error('JobController@rejectBid: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal menolak penawaran.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | PELANGGAN MENERIMA PENAWARAN MITRA
    |--------------------------------------------------------------------------
    */

        public function acceptBid(Request $request, $bidId)
    {
        // 1. Validasi PIN dari Flutter
        $request->validate([
            'pin' => 'required|string|size:6'
        ]);

        try {
            $pelangganId = auth()->id();
            $user = auth()->user();

            // 2. Cek apakah PIN yang dimasukkan benar
            if (!$user->pin || !Hash::check($request->pin, $user->pin)) {
                return response()->json([
                    'success' => false,
                    'message' => 'PIN yang Anda masukkan salah.',
                ], 400);
            }

            $result = DB::transaction(function () use (
                $bidId,
                $pelangganId
            ) {
                $selectedBid = job_bids::whereKey($bidId)
                    ->lockForUpdate()
                    ->first();

                if (!$selectedBid) {
                    throw new \RuntimeException('Penawaran tidak ditemukan.');
                }

                $job = jobs::whereKey($selectedBid->job_id)
                    ->lockForUpdate()
                    ->first();

                if (!$job || (int) $job->pelanggan_id !== (int) $pelangganId) {
                    throw new \RuntimeException('Kamu tidak memiliki akses ke pekerjaan ini.');
                }

                if ($job->status !== 'Mencari Mitra') {
                    throw new \RuntimeException('Pekerjaan sudah tidak menerima penawaran.');
                }

                if ($selectedBid->status !== 'Menunggu') {
                    throw new \RuntimeException('Penawaran ini sudah tidak tersedia.');
                }

                if (!$selectedBid->proposed_start_at || !$selectedBid->estimated_duration_minutes) {
                    throw new \RuntimeException('Penawaran Mitra belum memiliki informasi jadwal yang lengkap.');
                }

                $schedule = $this->calculateScheduleEnd(
                    $selectedBid->proposed_start_at,
                    (int) $selectedBid->estimated_duration_minutes
                );

                $scheduleStart = $schedule['start'];
                $scheduleEnd = $schedule['end'];

                if ($scheduleStart->lessThanOrEqualTo(now())) {
                    throw new \RuntimeException('Jadwal yang ditawarkan sudah lewat. Pilih penawaran dengan jadwal lain.');
                }

                $hargaDeal = (float) $selectedBid->offered_price;
                $budgetAwal = (float) $job->initial_budget;

                if ($hargaDeal <= 0) {
                    throw new \RuntimeException('Harga penawaran mitra tidak valid.');
                }

                // === PERBAIKAN LOGIKA HARGA ===
                // Jika harga mitra > budget awal, pastikan saldo user cukup untuk menutupi selisihnya
                $selisih = round($hargaDeal - $budgetAwal, 2);
                $wallet = Wallet::where('user_id', $pelangganId)->lockForUpdate()->first();

                if (!$wallet) {
                    throw new \RuntimeException('Wallet pelanggan tidak ditemukan.');
                }

                if ($selisih > 0) {
                    // Jika harga lebih mahal, potong saldo aktif (balance) pelanggan untuk ditambahkan ke escrow
                    if ((float) $wallet->balance < $selisih) {
                        throw new \RuntimeException('Saldo Anda tidak mencukupi untuk menutupi selisih harga penawaran mitra. Silakan Topup.');
                    }
                    
                    // Tambahkan selisih ke saldo tertahan (held_balance)
                    app(WalletService::class)->hold(
                        (int) $pelangganId,
                        $selisih,
                        (int) $job->id // Gunakan ID job atau payment ID yang sesuai
                    );
                }

                // Kunci Mitra
                $mitraUser = users::whereKey($selectedBid->mitra_id)->lockForUpdate()->first();
                if (!$mitraUser) {
                    throw new \RuntimeException('Akun Mitra tidak ditemukan.');
                }

                // Cek bentrok jadwal (tetap dipertahankan)
                $conflictingJob = jobs::where('mitra_id', $selectedBid->mitra_id)
                    ->whereIn('status', ['Terjadwal', 'Sedang Dikerjakan', 'Menunggu Konfirmasi Selesai'])
                    ->whereNotNull('scheduled_start_at')
                    ->whereNotNull('scheduled_end_at')
                    ->where('scheduled_start_at', '<', $scheduleEnd)
                    ->where('scheduled_end_at', '>', $scheduleStart)
                    ->lockForUpdate()
                    ->first();

                if ($conflictingJob) {
                    throw new \RuntimeException('Jadwal Mitra berbenturan dengan pekerjaan lain. Silakan pilih penawaran Mitra lain.');
                }

                // Validasi payment escrow
                $payment = Payment::where('job_id', $job->id)->lockForUpdate()->first();
                if (!$payment || $payment->status !== 'held') {
                    throw new \RuntimeException('Pembayaran tidak ditemukan atau tidak berada dalam status ditahan.');
                }

                // Hitung komisi
                $settings = system_setting::first();
                $commissionPercent = $settings ? (float) $settings->platform_commission_percent : 15.00;
                $commissionAmount = round($hargaDeal * ($commissionPercent / 100), 2);
                $mitraEarning = round($hargaDeal - $commissionAmount, 2);

                // Update Job
                $job->update([
                    'mitra_id' => $selectedBid->mitra_id,
                    'final_price' => $hargaDeal,
                    'scheduled_start_at' => $scheduleStart,
                    'scheduled_end_at' => $scheduleEnd,
                    'started_at' => null,
                    'status' => 'Terjadwal',
                ]);

                // Update Bid
                $selectedBid->update(['status' => 'Diterima Pelanggan']);

                // Tolak bid lain
                job_bids::where('job_id', $job->id)
                    ->where('id', '!=', $selectedBid->id)
                    ->where('status', 'Menunggu')
                    ->update(['status' => 'Ditolak']);

                // Update Payment
                $payment->update([
                    'mitra_id' => $selectedBid->mitra_id,
                    'job_amount' => $hargaDeal,
                    'commission_percent' => $commissionPercent,
                    'commission_amount' => $commissionAmount,
                    'mitra_earning' => $mitraEarning,
                    'total_paid' => $hargaDeal,
                ]);

                // Jika harga mitra LEBIH MURAH dari budget awal, kembalikan selisihnya ke saldo pelanggan
                $refundSelisih = round($budgetAwal - $hargaDeal, 2);
                if ($refundSelisih > 0) {
                    app(WalletService::class)->refundHold(
                        (int) $pelangganId,
                        $refundSelisih,
                        (int) $payment->id
                    );
                }

                return [
                    'job' => $job->fresh(),
                    'bid' => $selectedBid->fresh(),
                    'payment' => $payment->fresh(),
                    'mitra_id' => $selectedBid->mitra_id,
                ];
            }, 3);

            // Notifikasi
            try {
                $mitraUser = users::find($result['mitra_id']);
                if ($mitraUser) {
                    $mitraUser->notify(new BidAccepted($result['job']));
                }
            } catch (\Throwable $e) {
                Log::warning('Notifikasi BidAccepted gagal: ' . $e->getMessage());
            }

            $this->logActivity(
                $pelangganId,
                'Pelanggan menerima penawaran mitra',
                'Pelanggan menerima penawaran untuk "' . $result['job']->tittle . '".',
                'check_circle',
                'Sistem'
            );

            return response()->json([
                'success' => true,
                'message' => 'Mitra berhasil dipilih dan jadwal pekerjaan telah dikonfirmasi.',
                'data' => $result['job'],
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            Log::error('JobController@acceptBid: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem saat menerima penawaran.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | MITRA MEMULAI PEKERJAAN
    |--------------------------------------------------------------------------
    */

    public function startJob($id)
    {
        try {
            $mitraId = auth()->id();

            $result = DB::transaction(function () use ($id, $mitraId) {

                // 1. Kunci data Mitra agar proses pemeriksaan jadwal
                // tidak berjalan bersamaan dengan proses lain.
                users::whereKey($mitraId)
                    ->lockForUpdate()
                    ->firstOrFail();

                // 2. Ambil dan kunci pekerjaan.
                $job = jobs::whereKey($id)
                    ->lockForUpdate()
                    ->first();

                if (!$job) {
                    throw new \RuntimeException(
                        'Pekerjaan tidak ditemukan.'
                    );
                }

                if ((int) $job->mitra_id !== (int) $mitraId) {
                    throw new \RuntimeException(
                        'Kamu bukan Mitra yang ditugaskan pada pekerjaan ini.'
                    );
                }

                if ($job->status !== 'Terjadwal') {
                    throw new \RuntimeException(
                        'Pekerjaan tidak berada dalam status Terjadwal.'
                    );
                }

                if (!$job->scheduled_start_at || !$job->scheduled_end_at) {
                    throw new \RuntimeException(
                        'Informasi jadwal pekerjaan belum lengkap.'
                    );
                }

                $now = now();

                $scheduledStart = Carbon::parse($job->scheduled_start_at);
                $scheduledEnd = Carbon::parse($job->scheduled_end_at);

                // 3. Cegah Mitra memulai sebelum jadwal.
                if ($now->lt($scheduledStart)) {
                    throw new \RuntimeException(
                        'Belum waktunya memulai pekerjaan.'
                    );
                }

                // 4. Hitung durasi yang sebelumnya disepakati.
                $durationMinutes = $scheduledStart->diffInMinutes(
                    $scheduledEnd
                );

                if ($durationMinutes <= 0) {
                    throw new \RuntimeException(
                        'Durasi pekerjaan tidak valid.'
                    );
                }

                // 5. Hitung estimasi selesai berdasarkan waktu aktual.
                $actualStart = $now->copy();
                $newEstimatedEnd = $actualStart->copy()
                    ->addMinutes($durationMinutes);

                // 6. Periksa apakah jadwal baru bertabrakan
                // dengan pekerjaan Mitra lainnya.
                $conflictingJob = jobs::where('mitra_id', $mitraId)
                    ->where('id', '!=', $job->id)
                    ->whereIn('status', [
                        'Terjadwal',
                        'Sedang Dikerjakan',
                        'Menunggu Konfirmasi Selesai',
                    ])
                    ->whereNotNull('scheduled_start_at')
                    ->whereNotNull('scheduled_end_at')
                    ->where('scheduled_start_at', '<', $newEstimatedEnd)
                    ->where('scheduled_end_at', '>', $actualStart)
                    ->lockForUpdate()
                    ->first();

                // 7. Jika bentrok, jangan mulai pekerjaan dahulu.
                if ($conflictingJob) {
                    return [
                        'conflict' => true,
                        'conflicting_job' => $conflictingJob,
                        'new_start' => $actualStart,
                        'new_end' => $newEstimatedEnd,
                    ];
                }

                // 8. Jika tidak bentrok, mulai pekerjaan dan perbarui jadwal.
                $job->update([
                    'status' => 'Sedang Dikerjakan',
                    'started_at' => $actualStart,
                    'scheduled_start_at' => $actualStart,
                    'scheduled_end_at' => $newEstimatedEnd,
                ]);

                return [
                    'conflict' => false,
                    'job' => $job->fresh(),
                ];
            }, 3);

            // 9. Tangani konflik di luar transaksi.
            if ($result['conflict']) {
                return response()->json([
                    'success' => false,
                    'conflict' => true,
                    'message' => 'Keterlambatan memulai pekerjaan menyebabkan bentrok dengan jadwal pekerjaan berikutnya. Diperlukan penyelesaian jadwal terlebih dahulu.',
                    'data' => [
                        'current_job_id' => $id,
                        'conflicting_job_id' => $result['conflicting_job']->id,
                        'new_start_at' => $result['new_start'],
                        'new_end_at' => $result['new_end'],
                        'conflicting_start_at' => $result['conflicting_job']->scheduled_start_at,
                        'conflicting_end_at' => $result['conflicting_job']->scheduled_end_at,
                    ],
                ], 409);
            }

            $job = $result['job'];

            $this->logActivity(
                $mitraId,
                'Mitra memulai pekerjaan',
                'Mitra mulai mengerjakan "' . $job->tittle . '".',
                'play_circle',
                'Mitra'
            );

            return response()->json([
                'success' => true,
                'message' => 'Pekerjaan berhasil dimulai.',
                'data' => $job,
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            Log::error('JobController@startJob: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memulai pekerjaan.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | HERO RIGHT
    |--------------------------------------------------------------------------
    */

    public function getHeroData()
    {
        try {
            $latestJobWithBids = DB::table('jobs')
                ->where('status', 'Mencari Mitra')
                ->whereIn('id', function ($query) {
                    $query->select('job_id')
                        ->from('job_bids')
                        ->where('status', 'Menunggu');
                })
                ->latest()
                ->first();

            $activeMitraCount = DB::table('mitra_profiles')
                ->where('is_verified', 1)
                ->count();

            if (!$latestJobWithBids) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'title' => 'BELUM ADA PENAWARAN',
                        'offers' => [],
                        'active_mitra_count' => $activeMitraCount,
                    ],
                ]);
            }

            $bids = DB::table('job_bids')
                ->leftJoin('users', 'job_bids.mitra_id', '=', 'users.id')
                ->leftJoin(
                    'mitra_profiles',
                    'job_bids.mitra_id',
                    '=',
                    'mitra_profiles.user_id'
                )
                ->select(
                    'job_bids.id',
                    'job_bids.offered_price',
                    'job_bids.mitras_point_at_time',
                    'job_bids.proposed_start_at',
                    'job_bids.estimated_duration_minutes',
                    'users.name as user_name',
                    DB::raw(
                        'COALESCE(
                            mitra_profiles.point,
                            job_bids.mitras_point_at_time,
                            0
                        ) as total_point'
                    )
                )
                ->where('job_bids.job_id', $latestJobWithBids->id)
                ->where('job_bids.status', 'Menunggu')
                ->orderByDesc('total_point')
                ->limit(3)
                ->get();

            $offers = $bids->map(function ($bid, $index) {
                $userName = $bid->user_name ?? 'Mitra';
                $words = explode(' ', trim($userName));

                $initials = count($words) >= 2
                    ? strtoupper(substr($words[0], 0, 1)) .
                    strtoupper(substr($words[1], 0, 1))
                    : strtoupper(substr($userName, 0, 2));

                return [
                    'id' => $bid->id,
                    'active' => $index === 0,
                    'initials' => $initials,
                    'name' => $userName,
                    'rating' => null,
                    'point' => $bid->total_point . ' poin',

                    'price' => 'Rp ' .
                        number_format($bid->offered_price, 0, ',', '.'),

                    'proposed_start_at' => $bid->proposed_start_at,
                    'estimated_duration_minutes' =>
                    $bid->estimated_duration_minutes,

                    'badge' => $index === 0 ? 'ANTREAN #1' : null,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'title' => 'PENAWARAN MASUK — ' .
                        strtoupper($latestJobWithBids->tittle),

                    'offers' => $offers,
                    'active_mitra_count' => $activeMitraCount,
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('JobController@getHeroData: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data hero.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | MITRA UPLOAD BUKTI SELESAI
    |--------------------------------------------------------------------------
    */

    public function uploadProof(Request $request, $id)
    {
        $validated = $request->validate([
            'photo' => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
            'note' => 'nullable|string|max:500',
        ]);

        $path = null;

        try {
            $result = DB::transaction(function () use (
                $id,
                $validated,
                $request,
                &$path
            ) {
                $job = jobs::whereKey($id)
                    ->lockForUpdate()
                    ->first();

                if (!$job) {
                    throw new \RuntimeException(
                        'Pekerjaan tidak ditemukan.'
                    );
                }

                if ((int) $job->mitra_id !== (int) auth()->id()) {
                    throw new \RuntimeException(
                        'Anda bukan mitra pekerjaan ini.'
                    );
                }

                if ($job->status !== 'Sedang Dikerjakan') {
                    throw new \RuntimeException(
                        'Pekerjaan tidak dalam status sedang dikerjakan.'
                    );
                }

                $path = $request->file('photo')
                    ->store('completion_proofs', 'public');

                $job->update([
                    'completion_photo_url' => '/storage/' . $path,
                    'completion_submitted_at' => now(),

                    'completion_status' => 'pending',
                    'completion_verified_at' => null,

                    'completion_admin_note' => $validated['note'] ?? null,

                    'status' => 'Menunggu Konfirmasi Selesai',
                    'completed_at' => now(),
                ]);

                return $job->fresh();
            });

            $this->logActivity(
                auth()->id(),
                'Mitra upload bukti selesai',
                'Mitra mengupload bukti penyelesaian untuk "' .
                    $result->tittle . '".',
                'upload_file',
                'Mitra'
            );

            return response()->json([
                'success' => true,
                'message' => 'Bukti berhasil diupload, menunggu konfirmasi pelanggan.',
                'data' => $result,
            ]);
        } catch (\RuntimeException $e) {
            if ($path) {
                Storage::disk('public')->delete($path);
            }

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            if ($path) {
                Storage::disk('public')->delete($path);
            }

            Log::error('JobController@uploadProof: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengupload bukti pekerjaan.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | PELANGGAN VERIFIKASI BUKTI
    |--------------------------------------------------------------------------
    */

    public function verifyProof(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => 'required|in:approved,rejected',
            'note' => 'nullable|string|max:500',
        ]);

        try {
            $userId = auth()->id();

            $result = DB::transaction(function () use (
                $id,
                $userId,
                $validated
            ) {
                $job = jobs::whereKey($id)
                    ->lockForUpdate()
                    ->first();

                if (!$job) {
                    throw new \RuntimeException(
                        'Pekerjaan tidak ditemukan.'
                    );
                }

                if ((int) $job->pelanggan_id !== (int) $userId) {
                    throw new \RuntimeException(
                        'Kamu tidak memiliki akses untuk memverifikasi pekerjaan ini.'
                    );
                }

                if ($job->status !== 'Menunggu Konfirmasi Selesai') {
                    throw new \RuntimeException(
                        'Pekerjaan tidak sedang menunggu konfirmasi.'
                    );
                }

                if ($job->completion_status !== 'pending') {
                    throw new \RuntimeException(
                        'Bukti pekerjaan sudah pernah diverifikasi.'
                    );
                }

                $payment = Payment::where('job_id', $job->id)
                    ->lockForUpdate()
                    ->first();

                if (!$payment) {
                    throw new \RuntimeException(
                        'Pembayaran pekerjaan tidak ditemukan.'
                    );
                }

                if (
                    (int) $payment->pelanggan_id !== (int) $job->pelanggan_id ||
                    (int) $payment->mitra_id !== (int) $job->mitra_id
                ) {
                    throw new \RuntimeException(
                        'Data pembayaran tidak sesuai dengan pekerjaan.'
                    );
                }

                $decision = $validated['status'];
                $now = now();

                if ($decision === 'rejected') {
                    $job->update([
                        'completion_status' => 'rejected',
                        'completion_verified_at' => $now,

                        'completion_admin_note' => $validated['note'] ?? null,

                        'status' => 'Sedang Dikerjakan',
                    ]);

                    return [
                        'decision' => 'rejected',
                        'job' => $job->fresh(),
                        'payment' => $payment->fresh(),
                    ];
                }

                if ($payment->status !== 'held') {
                    throw new \RuntimeException(
                        'Pembayaran tidak dalam status ditahan atau sudah diproses.'
                    );
                }

                $totalPaid = (float) $payment->total_paid;
                $commission = (float) $payment->commission_amount;
                $mitraEarning = (float) $payment->mitra_earning;

                if ($mitraEarning <= 0) {
                    $mitraEarning = $totalPaid - $commission;
                }

                if (
                    $totalPaid <= 0 ||
                    $commission < 0 ||
                    $mitraEarning <= 0 ||
                    round($mitraEarning + $commission, 2) !== round($totalPaid, 2)
                ) {
                    throw new \RuntimeException(
                        'Nominal pembayaran atau pembagian dana tidak valid.'
                    );
                }

                app(WalletService::class)->releasePayment(
                    (int) $payment->pelanggan_id,
                    (int) $payment->mitra_id,
                    $totalPaid,
                    $mitraEarning,
                    $commission,
                    (int) $payment->id
                );

                $payment->update([
                    'status' => 'released',
                    'customer_accepted_at' => $now,
                    'released_at' => $now,
                    'mitra_earning' => $mitraEarning,
                ]);

                $job->update([
                    'completion_status' => 'approved',
                    'completion_verified_at' => $now,
                    'status' => 'Selesai',
                ]);

                $settings = system_setting::first();

                $pointsToAdd = $settings
                    ? (int) $settings->points_on_completion
                    : 10;

                $mitraProfile = mitra_profiles::where(
                    'user_id',
                    $payment->mitra_id
                )
                    ->lockForUpdate()
                    ->first();

                if ($mitraProfile) {
                    $mitraProfile->increment('point', $pointsToAdd);
                    $mitraProfile->increment('jobs_completed', 1);
                }

                return [
                    'decision' => 'approved',
                    'job' => $job->fresh(),
                    'payment' => $payment->fresh(),
                ];
            });

            $this->logActivity(
                $userId,

                $result['decision'] === 'approved'
                    ? 'Pelanggan menyetujui bukti pekerjaan'
                    : 'Pelanggan menolak bukti pekerjaan',

                $result['decision'] === 'approved'
                    ? 'Dana otomatis dicairkan untuk PAY-' .
                    $result['payment']->id
                    : 'Bukti pekerjaan ditolak untuk JOB-' . $id,

                $result['decision'] === 'approved'
                    ? 'check_circle'
                    : 'cancel',

                'Pelanggan'
            );

            if ($result['decision'] === 'approved') {
                return response()->json([
                    'success' => true,
                    'message' => 'Pekerjaan berhasil disetujui. Dana otomatis diteruskan ke saldo mitra dan komisi platform.',
                    'data' => [
                        'job' => $result['job'],
                        'payment' => $result['payment'],
                    ],
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Bukti pekerjaan ditolak. Mitra dapat memperbaiki pekerjaan dan mengunggah bukti kembali.',
                'data' => [
                    'job' => $result['job'],
                    'payment' => $result['payment'],
                ],
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            Log::error('JobController@verifyProof: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal memproses verifikasi pekerjaan.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | PEKERJAAN PELANGGAN UNTUK PENGADUAN
    |--------------------------------------------------------------------------
    */

    public function myJobsForComplaint()
    {
        try {
            $pelangganId = auth()->id();

            $eligibleStatuses = [
                'Sedang Dikerjakan',
                'Menunggu Konfirmasi Selesai',
                'Selesai',
            ];

            $jobList = jobs::with('mitra:id,name')
                ->where('pelanggan_id', $pelangganId)
                ->whereIn('status', $eligibleStatuses)
                ->orderByDesc('updated_at')
                ->get()
                ->map(function ($job) {
                    return [
                        'id' => $job->id,
                        'code' => $this->generateJobCode($job->id),

                        'tittle' => $job->tittle,
                        'status' => $job->status,

                        'mitra_name' => optional($job->mitra)->name,

                        'final_price' => $job->final_price,

                        'started_at' => $job->started_at,
                        'completed_at' => $job->completed_at,
                    ];
                });

            return response()->json([
                'success' => true,
                'message' => 'Berhasil mengambil daftar pekerjaan untuk pengaduan.',
                'total' => $jobList->count(),
                'data' => $jobList,
            ]);
        } catch (\Throwable $e) {
            Log::error('JobController@myJobsForComplaint: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | PEKERJAAN MITRA UNTUK PENGADUAN
    |--------------------------------------------------------------------------
    */

    public function myJobsForComplaintMitra()
    {
        try {
            $mitraId = auth()->id();

            $eligibleStatuses = [
                'Sedang Dikerjakan',
                'Menunggu Konfirmasi Selesai',
                'Selesai',
            ];

            $jobList = jobs::with('pelanggan:id,name')
                ->where('mitra_id', $mitraId)
                ->whereIn('status', $eligibleStatuses)
                ->orderByDesc('updated_at')
                ->get()
                ->map(function ($job) {
                    return [
                        'id' => $job->id,
                        'code' => $this->generateJobCode($job->id),

                        'tittle' => $job->tittle,
                        'status' => $job->status,

                        'pelanggan_name' => optional($job->pelanggan)->name,

                        'final_price' => $job->final_price,
                    ];
                });

            return response()->json([
                'success' => true,
                'message' => 'Berhasil mengambil daftar pekerjaan untuk pengaduan.',
                'total' => $jobList->count(),
                'data' => $jobList,
            ]);
        } catch (\Throwable $e) {
            Log::error('JobController@myJobsForComplaintMitra: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | PELANGGAN MEMBATALKAN PEKERJAAN
    |--------------------------------------------------------------------------
    */

    public function cancelJobByPelanggan(Request $request, $id)
    {
        try {
            $pelangganId = auth()->id();

            $job = DB::transaction(function () use (
                $id,
                $pelangganId
            ) {
                $job = jobs::whereKey($id)
                    ->lockForUpdate()
                    ->first();

                if (!$job) {
                    throw new \RuntimeException(
                        'Pekerjaan tidak ditemukan.'
                    );
                }

                if ((int) $job->pelanggan_id !== (int) $pelangganId) {
                    throw new \RuntimeException(
                        'Anda bukan pemilik pekerjaan ini.'
                    );
                }

                /*
                 * Pembatalan hanya diizinkan sebelum Mitra dipilih.
                 * Pekerjaan Terjadwal perlu kebijakan pembatalan
                 * tersendiri karena sudah ada kesepakatan.
                 */
                if ($job->status !== 'Mencari Mitra') {
                    throw new \RuntimeException(
                        'Pekerjaan hanya dapat dibatalkan langsung saat masih mencari Mitra. Untuk pekerjaan terjadwal, gunakan mekanisme permintaan pembatalan.'
                    );
                }

                $payment = Payment::where('job_id', $job->id)
                    ->lockForUpdate()
                    ->first();

                if (!$payment || $payment->status !== 'held') {
                    throw new \RuntimeException(
                        'Pembayaran pekerjaan tidak ditemukan atau tidak dapat direfund.'
                    );
                }

                $refundAmount = (float) $payment->total_paid;

                if ($refundAmount <= 0) {
                    throw new \RuntimeException(
                        'Nominal refund tidak valid.'
                    );
                }

                $wallet = Wallet::where('user_id', $pelangganId)
                    ->lockForUpdate()
                    ->first();

                if (!$wallet) {
                    throw new \RuntimeException(
                        'Wallet pelanggan tidak ditemukan.'
                    );
                }

                if ((float) $wallet->held_balance < $refundAmount) {
                    throw new \RuntimeException(
                        'Saldo escrow tidak mencukupi untuk proses refund.'
                    );
                }

                $job->update([
                    'status' => 'Dibatalkan',
                ]);

                job_bids::where('job_id', $job->id)
                    ->where('status', 'Menunggu')
                    ->update([
                        'status' => 'Ditolak',
                    ]);

                app(WalletService::class)->refundHold(
                    (int) $pelangganId,
                    $refundAmount,
                    (int) $payment->id
                );

                $payment->update([
                    'status' => 'refunded',
                ]);

                return $job->fresh();
            });

            $this->logActivity(
                $pelangganId,
                'Pelanggan membatalkan pekerjaan',
                'Pelanggan membatalkan "' . $job->tittle . '".',
                'cancel',
                'Pelanggan'
            );

            return response()->json([
                'success' => true,
                'message' => 'Pekerjaan berhasil dibatalkan. Saldo Anda telah dikembalikan.',
                'data' => $job,
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (\Throwable $e) {
            Log::error(
                'JobController@cancelJobByPelanggan: ' . $e->getMessage()
            );

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }
}
