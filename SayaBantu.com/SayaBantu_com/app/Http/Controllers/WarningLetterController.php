<?php

namespace App\Http\Controllers;

use App\Helpers\AdminTerritory;
use App\Models\WarningLetter;
use App\Models\users;
use App\Notifications\WarningLetterIssued;
use Illuminate\Http\Request;

class WarningLetterController extends Controller
{
    public function recipients(Request $request)
    {
        $data = $request->validate(['role' => 'required|in:Pelanggan,Mitra']);
        $query = users::with(['role:id,role_name', 'mitraProfile:id,user_id,city'])
            ->whereHas('role', fn ($roles) => $roles->where('role_name', $data['role']))
            ->where('is_active', true)
            ->orderBy('name');
        $this->constrainByAdminRegion($query, $data['role']);
        return response()->json(['success' => true, 'data' => $query->get(['id', 'name', 'email', 'phone', 'address'])]);
    }

    public function index()
    {
        $query = WarningLetter::with(['recipient:id,name,email', 'issuer:id,name'])->latest();
        $adminId = auth()->id();
        $query->where('admin_id', $adminId);
        return response()->json(['success' => true, 'data' => $query->limit(200)->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'recipient_role' => 'required|in:Pelanggan,Mitra',
            'level' => 'required|integer|in:1,2,3',
            'subject' => 'required|string|max:150',
            'reason' => 'required|string|max:3000',
        ]);

        $recipient = users::with(['role', 'mitraProfile'])->findOrFail($data['user_id']);
        if ($recipient->role?->role_name !== $data['recipient_role']) {
            return response()->json(['success' => false, 'message' => 'Peran penerima tidak sesuai.'], 422);
        }
        if (!$recipient->is_active) {
            return response()->json(['success' => false, 'message' => 'Akun penerima tidak aktif.'], 422);
        }
        if (!$this->isInAdminRegion($recipient, $data['recipient_role'])) {
            return response()->json(['success' => false, 'message' => 'Penerima berada di luar wilayah tugas Anda.'], 403);
        }

        $warning = WarningLetter::create($data + ['admin_id' => auth()->id()]);
        $recipient->notify(new WarningLetterIssued($warning));

        return response()->json(['success' => true, 'message' => 'Surat peringatan berhasil dikirim.', 'data' => $warning->load(['recipient:id,name,email', 'issuer:id,name'])], 201);
    }

    private function constrainByAdminRegion($query, string $role): void
    {
        $region = AdminTerritory::area();
        if ($region === '') {
            $query->whereRaw('1 = 0');
            return;
        }
        $pattern = '%' . addcslashes($region, '%_\\') . '%';
        if ($role === 'Mitra') {
            $query->whereHas('mitraProfile', fn ($profile) => AdminTerritory::constrainMitraProfiles($profile));
            return;
        }
        $query->where(function ($customers) use ($pattern) {
            AdminTerritory::constrainAddress($customers)
                ->orWhereHas('jobsAsPelanggan', fn ($jobs) => AdminTerritory::constrainJobs($jobs));
        });
    }

    private function isInAdminRegion(users $recipient, string $role): bool
    {
        $region = AdminTerritory::area();
        if ($region === '') return false;
        if ($role === 'Mitra') return AdminTerritory::allowsMitraProfile($recipient->mitraProfile);
        if (AdminTerritory::addressMatches($recipient->address)) return true;
        return $recipient->jobsAsPelanggan()->where(function ($jobs) {
            AdminTerritory::constrainJobs($jobs);
        })->exists();
    }
}
