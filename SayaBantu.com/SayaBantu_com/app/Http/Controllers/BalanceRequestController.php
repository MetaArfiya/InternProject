<?php

namespace App\Http\Controllers;

use App\Models\BalanceRequest;
use App\Helpers\AdminTerritory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BalanceRequestController extends Controller
{
    public function customerIndex()
    {
        $user = \App\Models\users::findOrFail(auth()->id());
        return response()->json(['success' => true, 'balance' => (int) $user->balance, 'data' => BalanceRequest::where('user_id', $user->id)->latest()->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'type' => 'required|in:top_up,withdrawal',
            'amount' => 'required|integer|min:10000|max:100000000',
            'bank_name' => 'required|string|max:100',
            'account_number' => 'required|string|max:50',
            'account_name' => 'required|string|max:150',
            'note' => 'nullable|string|max:1000',
        ]);
        $item = DB::transaction(function () use ($data) {
            $user = \App\Models\users::whereKey(auth()->id())->lockForUpdate()->firstOrFail();
            if ($data['type'] === 'withdrawal' && $user->balance < $data['amount']) {
                abort(422, 'Saldo tidak mencukupi untuk pengajuan penarikan.');
            }
            if ($data['type'] === 'withdrawal') $user->decrement('balance', $data['amount']);
            return BalanceRequest::create($data + ['user_id' => $user->id]);
        });
        return response()->json(['success' => true, 'message' => 'Pengajuan dikirim ke admin.', 'data' => $item], 201);
    }

    public function adminIndex()
    {
        $query = BalanceRequest::with(['user:id,name,email,phone', 'reviewer:id,name'])->latest();
        $this->constrainToAdminRegion($query);
        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function review(Request $request, int $id)
    {
        $data = $request->validate(['status' => 'required|in:approved,rejected', 'admin_note' => 'nullable|string|max:1000']);
        $item = DB::transaction(function () use ($id, $data) {
            $query = BalanceRequest::with('user')->lockForUpdate();
            $this->constrainToAdminRegion($query);
            $item = $query->findOrFail($id);
            if ($item->status !== 'pending') abort(409, 'Pengajuan sudah ditinjau.');
            $user = \App\Models\users::whereKey($item->user_id)->lockForUpdate()->firstOrFail();
            if ($item->type === 'top_up' && $data['status'] === 'approved') $user->increment('balance', $item->amount);
            if ($item->type === 'withdrawal' && $data['status'] === 'rejected') $user->increment('balance', $item->amount);
            $item->fill($data + ['reviewed_by' => auth()->id()])->save();
            return $item->load('user:id,name,email');
        });
        return response()->json(['success' => true, 'message' => 'Pengajuan diperbarui.', 'data' => $item]);
    }

    private function constrainToAdminRegion($query): void
    {
        if (auth()->user()->role?->role_name !== 'Admin') return;

        $region = AdminTerritory::area();
        if ($region === '') {
            $query->whereRaw('1 = 0');
            return;
        }

        $pattern = '%' . addcslashes($region, '%_\\') . '%';
        $query->whereHas('user', function ($users) use ($pattern) {
            $users->where(function ($addresses) {
                AdminTerritory::constrainAddress($addresses);
            })
                ->orWhereHas('jobsAsPelanggan', fn ($jobs) => AdminTerritory::constrainJobs($jobs));
        });
    }
}
