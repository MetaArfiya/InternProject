<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Response;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

Route::get('/post-job', function () {
    return view('jobs.create');
});

Route::get('/storage/{folder}/{filename}', function ($folder, $filename) {
    $path = $folder . '/' . $filename;
    
    // Cek apakah file benar-benar ada di storage/app/public
    if (!Storage::disk('public')->exists($path)) {
        abort(404);
    }
    
    $file = Storage::disk('public')->get($path);
    $type = Storage::disk('public')->mimeType($path);
    
    // Kembalikan file dalam bentuk respon gambar, bukan download
    return Response::make($file, 200)->header("Content-Type", $type);
});