import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

class CompletionProofDialog extends StatefulWidget {
  final int offerId;

  const CompletionProofDialog({
    super.key,
    required this.offerId,
  });

  @override
  State<CompletionProofDialog> createState() =>
      _CompletionProofDialogState();
}

class _CompletionProofDialogState
    extends State<CompletionProofDialog> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _descriptionController =
      TextEditingController();

  Uint8List? _selectedImage;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // PILIH FOTO
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      final Uint8List imageBytes =
          await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = imageBytes;
      });
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Gagal memilih foto: $e',
      );
    }
  }

  // ============================================================
  // PILIH SUMBER FOTO
  // ============================================================

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              20,
              24,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xffD1D5DB),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // KAMERA
                // ==================================================

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xffDCFCE7),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xff16A34A),
                    ),
                  ),
                  title: const Text(
                    'Kamera',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Ambil foto pekerjaan sekarang',
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    _pickImage(
                      ImageSource.camera,
                    );
                  },
                ),

                const SizedBox(height: 8),

                // ==================================================
                // GALERI
                // ==================================================

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xffDBEAFE),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xff2563EB),
                    ),
                  ),
                  title: const Text(
                    'Galeri',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Pilih foto dari galeri perangkat',
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    _pickImage(
                      ImageSource.gallery,
                    );
                  },
                ),

                const SizedBox(height: 8),

                // ==================================================
                // BATAL
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        bottomSheetContext,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HAPUS FOTO
  // ============================================================

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // ============================================================
  // VALIDASI
  // ============================================================

  bool get _isFormValid {
    final description =
        _descriptionController.text.trim();

    return _selectedImage != null &&
        description.isNotEmpty;
  }

  // ============================================================
  // KIRIM BUKTI KE LARAVEL
  // ============================================================

  Future<void> _submitProof() async {
    FocusScope.of(context).unfocus();

    if (_selectedImage == null) {
      _showError(
        'Silakan tambahkan foto bukti pekerjaan terlebih dahulu.',
      );
      return;
    }

    final description =
        _descriptionController.text.trim();

    if (description.isEmpty) {
      _showError(
        'Silakan masukkan deskripsi pekerjaan.',
      );
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      debugPrint(
        '📤 Mengirim bukti pekerjaan...',
      );

      debugPrint(
        '📌 Offer ID: ${widget.offerId}',
      );

      // ========================================================
      // KIRIM MULTIPART
      // ========================================================

      final response =
          await ApiService.postMultipart(
        '/mitra/offers/${widget.offerId}/completion-proof',
        {
          'description': description,
        },
        files: {
          'photo': _selectedImage!,
        },
      );

      debugPrint(
        '📥 STATUS: ${response.statusCode}',
      );

      debugPrint(
        '📦 RESPONSE: ${response.body}',
      );

      // ========================================================
      // BERHASIL
      // ========================================================

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (!mounted) return;

        Navigator.pop(
          context,
          CompletionProofResult(
            image: _selectedImage!,
            description: description,
          ),
        );

        return;
      }

      // ========================================================
      // GAGAL
      // ========================================================

      String message =
          'Gagal mengirim bukti pekerjaan.';

      try {
        final decoded =
            response.body.isNotEmpty
                ? jsonDecode(response.body)
                : null;

        if (decoded is Map<String, dynamic>) {
          if (decoded['message'] != null) {
            message =
                decoded['message'].toString();
          }
        }
      } catch (_) {
        // Response bukan JSON.
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        '$message\nStatus: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint(
        '❌ ERROR KIRIM BUKTI: $e',
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        'Terjadi kesalahan saat mengirim bukti:\n$e',
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight:
              mediaQuery.size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xffDCFCE7),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xff16A34A),
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bukti Pekerjaan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Kirim bukti bahwa pekerjaan telah selesai.',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Color(0xff6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                            );
                          },
                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ==================================================
              // FOTO
              // ==================================================

              const Text(
                'Foto Pekerjaan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Tambahkan foto sebagai bukti pekerjaan yang telah selesai.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xff6B7280),
                ),
              ),

              const SizedBox(height: 14),

              _buildImageSection(),

              const SizedBox(height: 24),

              // ==================================================
              // DESKRIPSI
              // ==================================================

              const Text(
                'Deskripsi Pekerjaan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _descriptionController,
                maxLines: 5,
                minLines: 4,
                maxLength: 500,
                textInputAction:
                    TextInputAction.newline,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText:
                      'Contoh: Pekerjaan pemasangan AC telah selesai dilakukan dan AC sudah dapat digunakan dengan baik.',
                  hintStyle: const TextStyle(
                    color: Color(0xff9CA3AF),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor:
                      const Color(0xffF9FAFB),
                  contentPadding:
                      const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: Color(0xffE5E7EB),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: Color(0xffE5E7EB),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: Color(0xff16A34A),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // INFO
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xffF0FDF4),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        const Color(0xffBBF7D0),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xff16A34A),
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Pastikan foto dan deskripsi sesuai dengan pekerjaan yang telah kamu lakukan.',
                        style: TextStyle(
                          color:
                              Color(0xff166534),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // BUTTON
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );
                            },
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(
                          0xff374151,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        side: const BorderSide(
                          color: Color(
                            0xffD1D5DB,
                          ),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _isFormValid &&
                                  !_isSubmitting
                              ? _submitProof
                              : null,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 19,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Mengirim...'
                            : 'Kirim Bukti',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xff16A34A,
                        ),
                        disabledBackgroundColor:
                            const Color(
                          0xffD1D5DB,
                        ),
                        foregroundColor:
                            Colors.white,
                        disabledForegroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
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

  // ============================================================
  // IMAGE SECTION
  // ============================================================

  Widget _buildImageSection() {
    // ----------------------------------------------------------
    // BELUM ADA FOTO
    // ----------------------------------------------------------

    if (_selectedImage == null) {
      return InkWell(
        onTap: _showImageSourceOptions,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xffF9FAFB),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffD1D5DB),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      const Color(0xffDCFCE7),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color:
                      Color(0xff16A34A),
                  size: 30,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Tambahkan Foto',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Kamera atau Galeri',
                style: TextStyle(
                  color:
                      Color(0xff6B7280),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // SUDAH ADA FOTO
    // ----------------------------------------------------------

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffD1D5DB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.memory(
            _selectedImage!,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
          ),

          // Gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:
                      Alignment.topCenter,
                  end:
                      Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: 0.7,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ganti Foto
          Positioned(
            left: 12,
            bottom: 12,
            child: OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : _showImageSourceOptions,
              icon: const Icon(
                Icons.edit_outlined,
                size: 17,
              ),
              label: const Text(
                'Ganti Foto',
              ),
              style:
                  OutlinedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    const Color(0xff374151),
                side: BorderSide.none,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Hapus Foto
          Positioned(
            right: 12,
            bottom: 12,
            child: IconButton(
              onPressed: _isSubmitting
                  ? null
                  : _removeImage,
              tooltip: 'Hapus foto',
              style:
                  IconButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    Colors.red,
              ),
              icon: const Icon(
                Icons.delete_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// HASIL DIALOG
// ================================================================

class CompletionProofResult {
  final Uint8List image;
  final String description;

  const CompletionProofResult({
    required this.image,
    required this.description,
  });
}