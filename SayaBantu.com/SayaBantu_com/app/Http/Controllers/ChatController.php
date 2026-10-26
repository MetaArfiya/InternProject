<?php

namespace App\Http\Controllers;

use App\Models\jobs;
use App\Models\JobMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\Notification;

class ChatController extends Controller
{
    // GET /api/jobs/{id}/chat
    public function index(Request $request, $jobId)
    {
        $user = $request->user();
        $job  = jobs::findOrFail($jobId);

        if (!$this->canAccess($job, $user)) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak.',
            ], 403);
        }

        // Tandai pesan dari lawan bicara sebagai "sudah dibaca"
        JobMessage::where('job_id', $jobId)
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        // Tambahkan profile_photo ke dalam select sender
        $messages = JobMessage::with(['sender:id,name,role_id,photo_profile', 'sender.role'])
            ->where('job_id', $jobId)
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(function ($m) use ($user) {
                // Buat URL lengkap untuk foto profil
                $photoUrl = null;
                if ($m->sender && $m->sender->photo_profile) {
                    $photoUrl = url('/api/images/profile/' . basename($m->sender->photo_profile));
                }

                return [
                    'id'           => $m->id,
                    'message'      => $m->message,
                    'is_mine'      => $m->sender_id === $user->id,
                    'sender_name'  => $m->sender->name ?? 'User',
                    'sender_role'  => $this->extractRoleName($m->sender),
                    'sender_photo' => $photoUrl, // <-- TAMBAHKAN INI
                    'time'         => $m->created_at->format('H:i'),
                    'created_at'   => $m->created_at->toIso8601String(),
                ];
            });

        return response()->json([
            'success' => true,
            'data'    => $messages,
        ]);
    }

        // POST /api/jobs/{id}/chat
    public function store(Request $request, $jobId)
    {
        $request->validate([
            'message' => 'required|string|max:1000',
        ]);

        $user = $request->user();
        $job  = jobs::findOrFail($jobId);

        if (!$this->canAccess($job, $user)) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak.',
            ], 403);
        }

        $msg = JobMessage::create([
            'job_id'    => $jobId,
            'sender_id' => $user->id,
            'message'   => $request->message,
        ]);

        // ========================================================
        // 🆕 TAMBAHKAN BLOK INI UNTUK NOTIFIKASI CHAT
        // ========================================================
        $roleRaw = $user->role ?? null;
        $roleName = is_object($roleRaw) ? ($roleRaw->role_name ?? '') : (string) $roleRaw;
        $role = strtolower(trim($roleName));

        $receiverId = null;
        if ($role === 'pelanggan') {
            $receiverId = $job->mitra_id;
        } elseif ($role === 'mitra') {
            $receiverId = $job->pelanggan_id;
        }

        if ($receiverId) {
            // Menggunakan Query Builder untuk menyisipkan ke tabel notifications Laravel
            \Illuminate\Support\Facades\DB::table('notifications')->insert([
                'id' => (string) \Illuminate\Support\Str::uuid(), // Laravel notif butuh UUID untuk ID
                'type' => 'App\Notifications\NewChatMessage', // Bebas mau diisi apa
                'notifiable_type' => 'App\Models\users', // Sesuaikan dengan model user kamu
                'notifiable_id' => $receiverId,
                'data' => json_encode([
                    'job_id' => $jobId,
                    'message' => $user->name . ' mengirim pesan: "' . substr($request->message, 0, 30) . '..."',
                    'type' => 'chat',
                ]),
                'read_at' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
        // ========================================================

        // Buat URL lengkap untuk foto profil pengirim
        $photoUrl = null;
        if ($user->photo_profile) {
            $photoUrl = url('/api/images/profile/' . basename($user->photo_profile));
        }

        return response()->json([
            'success' => true,
            'message' => 'Pesan terkirim.',
            'data'    => [
                'id'           => $msg->id,
                'message'      => $msg->message,
                'is_mine'      => true,
                'sender_name'  => $user->name,
                'sender_role'  => $this->extractRoleName($user),
                'sender_photo' => $photoUrl, 
                'time'         => $msg->created_at->format('H:i'),
                'created_at'   => $msg->created_at->toIso8601String(),
            ],
        ]);
    }

    // ============================================================
    // HELPER — Ambil role_name (string) dari user / object relasi
    // ============================================================
    private function extractRoleName($user): string
    {
        if (!$user) return '';

        $roleRaw = $user->role ?? null;

        if (is_object($roleRaw)) {
            return (string) ($roleRaw->role_name ?? '');
        }

        return (string) ($roleRaw ?? '');
    }

    // ============================================================
    // HELPER — Cek akses
    // ============================================================
    private function canAccess(jobs $job, $user): bool
    {
        $roleRaw = $user->role ?? null;

        if (is_object($roleRaw)) {
            $roleName = $roleRaw->role_name ?? '';
        } else {
            $roleName = (string) $roleRaw;
        }

        $role = strtolower(trim($roleName));

        // Pelanggan pemilik job
        if ($role === 'pelanggan' && $job->pelanggan_id == $user->id) {
            return true;
        }

        // Mitra yang mengerjakan job
        if ($role === 'mitra' && $job->mitra_id == $user->id) {
            return true;
        }

        Log::info('CHAT ACCESS DENIED', [
            'user_id'       => $user->id,
            'role_fixed'    => $role,
            'job_id'        => $job->id,
            'job_pelanggan' => $job->pelanggan_id,
            'job_mitra'     => $job->mitra_id,
        ]);

        return false;
    }
}