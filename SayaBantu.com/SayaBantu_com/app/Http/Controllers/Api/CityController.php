<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\City;
use Illuminate\Http\Request;

class CityController extends Controller
{
    /**
     * Menampilkan seluruh daftar kota.
     */
    public function index()
    {
        try {
            $cities = City::orderBy('name', 'asc')
                ->get(['id', 'name']);

            return response()->json([
                'success' => true,
                'message' => 'Daftar kota berhasil diambil.',
                'data' => $cities,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil daftar kota.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Menambahkan kota baru.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100|unique:cities,name',
        ]);

        $city = City::create([
            'name' => $validated['name'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Kota berhasil ditambahkan.',
            'data' => $city,
        ], 201);
    }

    /**
     * Memperbarui kota.
     */
    public function update(Request $request, $id)
    {
        $city = City::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:100|unique:cities,name,' . $id,
        ]);

        $city->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Kota berhasil diperbarui.',
            'data' => $city,
        ], 200);
    }

    /**
     * Menghapus kota.
     */
    public function destroy($id)
    {
        $city = City::findOrFail($id);

        $city->delete();

        return response()->json([
            'success' => true,
            'message' => 'Kota berhasil dihapus.',
        ], 200);
    }
}