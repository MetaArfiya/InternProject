// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

// import '../../models/job_model.dart';

// class PostingJasaDialog extends StatefulWidget {
//   const PostingJasaDialog({super.key});

//   @override
//   State<PostingJasaDialog> createState() => _PostingJasaDialogState();
// }

// class _PostingJasaDialogState extends State<PostingJasaDialog> {
//   final _judulController = TextEditingController();
//   final _deskripsiController = TextEditingController();
//   final _budgetController = TextEditingController();
//   final _lokasiController = TextEditingController();

//   File? _selectedImage;

//   String _kategori = "Service AC";

//   final List<String> kategoriList = [
//     "Service AC",
//     "Plumbing",
//     "Listrik",
//     "Cat Rumah",
//     "Kebersihan",
//     "Lainnya",
//   ];

//   @override
//   void dispose() {
//     _judulController.dispose();
//     _deskripsiController.dispose();
//     _budgetController.dispose();
//     _lokasiController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();

//     final XFile? image = await picker.pickImage(
//       source: ImageSource.gallery,
//     );

//     if (image != null) {
//       setState(() {
//         _selectedImage = File(image.path);
//       });
//     }
//   }

//   void _postingJasa() {
//     if (_judulController.text.isEmpty ||
//         _deskripsiController.text.isEmpty ||
//         _budgetController.text.isEmpty ||
//         _lokasiController.text.isEmpty ||
//         _selectedImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Lengkapi semua data dan unggah foto kendala."),
//         ),
//       );
//       return;
//     }

//     final job = JobModel(
//       title: _judulController.text,
//       description: _deskripsiController.text,
//       price: "Rp${_budgetController.text}",
//       status: "Mencari Mitra",
//       time: "Baru saja",
//       offers: [],
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Posting jasa berhasil dibuat."),
//       ),
//     );

//     Navigator.pop(context, job);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Container(
//         width: 650,
//         padding: const EdgeInsets.all(28),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Posting Jasa Baru",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 30),

//               const Text("Judul Jasa"),
//               const SizedBox(height: 8),

//               TextField(
//                 controller: _judulController,
//                 decoration: const InputDecoration(
//                   hintText: "Contoh: Service AC Bocor",
//                   border: OutlineInputBorder(),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               const Text("Kategori"),
//               const SizedBox(height: 8),

//               DropdownButtonFormField<String>(
//                 value: _kategori,
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(),
//                 ),
//                 items: kategoriList.map((e) {
//                   return DropdownMenuItem(
//                     value: e,
//                     child: Text(e),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _kategori = value!;
//                   });
//                 },
//               ),

//               const SizedBox(height: 20),

//               const Text("Deskripsi"),
//               const SizedBox(height: 8),

//               TextField(
//                 controller: _deskripsiController,
//                 maxLines: 4,
//                 decoration: const InputDecoration(
//                   hintText: "Jelaskan masalah secara detail...",
//                   border: OutlineInputBorder(),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               const Text("Budget"),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _budgetController,
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [
//                   CurrencyInputFormatter(
//                     leadingSymbol: "Rp ",
//                     thousandSeparator: ThousandSeparator.Period,
//                     mantissaLength: 0,
//                   ),
//                 ],
//                 decoration: const InputDecoration(
//                   hintText: "Rp 0",
//                   border: OutlineInputBorder(),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               const Text("Lokasi"),
//               const SizedBox(height: 8),

//               TextField(
//                 controller: _lokasiController,
//                 decoration: const InputDecoration(
//                   hintText: "Masukkan alamat",
//                   prefixIcon: Icon(Icons.location_on_outlined),
//                   border: OutlineInputBorder(),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               const Text("Foto Kendala"),
//               const SizedBox(height: 8),

//               InkWell(
//                 onTap: _pickImage,
//                 child: Container(
//                   height: 180,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: _selectedImage == null
//                       ? const Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.cloud_upload_outlined,
//                               size: 40,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 10),
//                             Text(
//                               "Klik untuk upload foto",
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           ],
//                         )
//                       : ClipRRect(
//                           borderRadius: BorderRadius.circular(14),
//                           child: Image.file(
//                             _selectedImage!,
//                             fit: BoxFit.cover,
//                             width: double.infinity,
//                           ),
//                         ),
//                 ),
//               ),

//               const SizedBox(height: 30),

//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       child: const Text("Batal"),
//                     ),
//                   ),

//                   const SizedBox(width: 18),

//                   Expanded(
//                     flex: 2,
//                     child: ElevatedButton.icon(
//                       onPressed: _postingJasa,
//                       icon: const Icon(Icons.rocket_launch),
//                       label: const Text("Posting Sekarang"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xffF97316),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 18),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/job_model.dart';

import '../../services/api_service.dart';

class PostingJasaDialog extends StatefulWidget {
  const PostingJasaDialog({super.key});

  @override
  State<PostingJasaDialog> createState() => _PostingJasaDialogState();
}

class _PostingJasaDialogState extends State<PostingJasaDialog> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _budgetController = TextEditingController();
  final _lokasiController = TextEditingController();

  XFile? _pickedFile;
  Uint8List? _imageBytes;

  bool _isSubmitting = false;

  String _kategori = "Service AC";

  final List<String> kategoriList = [
    "Service AC",
    "Plumbing",
    "Listrik",
    "Cat Rumah",
    "Kebersihan",
    "Lainnya",
  ];

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _budgetController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _postingJasa() async {
    if (_judulController.text.trim().isEmpty ||
        _deskripsiController.text.trim().isEmpty ||
        _budgetController.text.trim().isEmpty ||
        _lokasiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data yang diperlukan."),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Ambil Token dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // ⚠️ PASTIKAN KEY 'auth_token' SAMA DENGAN SAAT KODE LOGIN
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

      debugPrint("----------------------------------------");
      debugPrint("🔑 TOKEN DIKIRIM: '$token'");
      debugPrint("----------------------------------------");

      if (token.isEmpty) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sesi telah berakhir, silakan login kembali."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. Bersihkan Budget
      final rawBudget = _budgetController.text
          .replaceAll('Rp', '')
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();

      // 3. Buat Multipart Request
      final uri = Uri.parse('${ApiService.baseUrl}/jobs');
      final request = http.MultipartRequest('POST', uri);

      // 4. Set Headers Eksplisit
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      // 5. Data Fields
      request.fields['tittle'] = _judulController.text.trim();
      request.fields['description'] = _deskripsiController.text.trim();
      request.fields['initial_budget'] = rawBudget;
      request.fields['location'] = _lokasiController.text.trim();
      request.fields['category'] = _kategori;

      // 6. File Gambar
      if (_pickedFile != null && _imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _imageBytes!,
            filename: _pickedFile!.name,
          ),
        );
      }

      // 7. Kirim Request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("RESPONSE STATUS: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.body}");

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          try {
            final resData = jsonDecode(response.body);
            final jobJson = resData['data'] ?? resData;
            final JobModel createdJob = JobModel.fromJson(jobJson);

            // 1. Tampilkan notifikasi terlebih dahulu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Posting jasa berhasil dibuat."),
                backgroundColor: Colors.green,
              ),
            );

            // 2. Tutup dialog dan kirim objek createdJob
            Navigator.pop(context, createdJob);
          } catch (e) {
            debugPrint("Gagal parsing JobModel: $e");
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Posting Jasa Baru",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Text("Judul Jasa"),
              const SizedBox(height: 8),
              TextField(
                controller: _judulController,
                decoration: const InputDecoration(
                  hintText: "Contoh: Service AC Bocor",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Kategori"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _kategori,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: kategoriList.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _kategori = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text("Deskripsi"),
              const SizedBox(height: 8),
              TextField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Jelaskan masalah secara detail...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Budget"),
              const SizedBox(height: 8),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(
                    leadingSymbol: "Rp ",
                    thousandSeparator: ThousandSeparator.Period,
                    mantissaLength: 0,
                  ),
                ],
                decoration: const InputDecoration(
                  hintText: "Rp 0",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Lokasi"),
              const SizedBox(height: 8),
              TextField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  hintText: "Masukkan alamat",
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Foto Kendala (Opsional)"),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _imageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Klik untuk upload foto",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _postingJasa,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.rocket_launch),
                      label: Text(_isSubmitting ? "Memproses..." : "Posting Sekarang"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}