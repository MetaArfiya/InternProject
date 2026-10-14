import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';

class RatingDialog extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  final String mitraName;

  const RatingDialog({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.mitraName,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _stars = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _starLabel {
    switch (_stars) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Bagus';
      case 5:
        return 'Sangat Bagus';
      default:
        return 'Pilih bintang';
    }
  }

  // ✅ Warna label bintang — tetap konotasi masing-masing
  // (merah → buruk, hijau → bagus, abu → belum pilih)
  Color get _starColor {
    switch (_stars) {
      case 1:
        return const Color(0xFFDC2626); // merah
      case 2:
        return const Color(0xFFF97316); // orange
      case 3:
        return const Color(0xFFF59E0B); // amber
      case 4:
        return const Color(0xFF84CC16); // light green
      case 5:
        return const Color(0xFF16A34A); // green
      default:
        return AppColors.grey500;
    }
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih bintang terlebih dahulu.'),
          backgroundColor: Color(0xFFF59E0B), // amber
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.post(
        '/pelanggan/ratings',
        {
          'job_id': widget.jobId,
          'stars': _stars,
          'comment': _commentController.text.trim(),
        },
      );

      debugPrint('⭐ POST RATING: ${response.statusCode}');
      debugPrint('⭐ BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      String message = 'Gagal mengirim rating.';
      try {
        final decoded = jsonDecode(response.body);
        message = decoded['message']?.toString() ?? message;
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              // ✅ dari amber → mint soft
              color: AppColors.mint.withValues(alpha:0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star_rate_rounded,
              // tetap amber (bintang)
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beri Rating',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bagaimana hasil kerja mitra?',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Info Job & Mitra =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha:0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.work_outline,
                            size: 16, color: AppColors.grey500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.jobTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: AppColors.grey500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.mitraName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== Bintang =====
              Center(
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          final filled = starIndex <= _stars;

                          return GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : () => setState(() => _stars = starIndex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 46,
                                // tetap amber untuk bintang
                                color: filled
                                    ? const Color(0xFFF59E0B)
                                    : AppColors.grey300,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _starLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _starColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== Komentar =====
              const Text(
                'Komentar (opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText:
                      'Ceritakan pengalaman Anda bekerja dengan mitra ini...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primaryTeal,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  counterStyle: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.grey600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: (_stars == 0 || _isSubmitting) ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Rating'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal, // ← dari orange
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.grey300,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}