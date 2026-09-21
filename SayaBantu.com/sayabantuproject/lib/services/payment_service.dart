// // lib/services/payment_service.dart

// import 'dart:convert';
// import 'dart:typed_data';

// import 'api_service.dart';

// class PaymentService {
//   /// ============================================================
//   /// PELANGGAN — Ambil detail pembayaran + info rekening platform
//   /// GET /pelanggan/payments/{id}
//   /// ============================================================
//   static Future<Map<String, dynamic>?> getPelangganPaymentDetail(int id) async {
//     try {
//       final response = await ApiService.get('/pelanggan/payments/$id');
//       if (response.statusCode != 200) return null;

//       final decoded = jsonDecode(response.body);
//       if (decoded['success'] != true) return null;

//       return Map<String, dynamic>.from(decoded['data']);
//     } catch (e) {
//       print('❌ PaymentService.getPelangganPaymentDetail: $e');
//       return null;
//     }
//   }

//   /// ============================================================
//   /// PELANGGAN — Upload bukti transfer
//   /// POST /pelanggan/payments/{id}/upload-proof
//   /// ============================================================
//   static Future<bool> uploadCustomerProof({
//     required int paymentId,
//     required Uint8List imageBytes,
//     required String bankName,
//     required String accountName,
//     String? note,
//   }) async {
//     try {
//       final response = await ApiService.postMultipart(
//         '/pelanggan/payments/$paymentId/upload-proof',
//         {
//           'bank_name': bankName,
//           'account_name': accountName,
//           if (note != null && note.isNotEmpty) 'note': note,
//         },
//         files: {
//           'proof': imageBytes,
//         },
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       print('❌ PaymentService.uploadCustomerProof: $e');
//       return false;
//     }
//   }

//   /// ============================================================
//   /// ADMIN — Ambil detail pembayaran + rekening mitra
//   /// GET /admin/payments/{id}
//   /// ============================================================
//   static Future<Map<String, dynamic>?> getAdminPaymentDetail(int id) async {
//     try {
//       final response = await ApiService.get('/admin/payments/$id');
//       if (response.statusCode != 200) return null;

//       final decoded = jsonDecode(response.body);
//       if (decoded['success'] != true) return null;

//       return Map<String, dynamic>.from(decoded['data']);
//     } catch (e) {
//       print('❌ PaymentService.getAdminPaymentDetail: $e');
//       return null;
//     }
//   }

//   /// ============================================================
//   /// ADMIN — Verifikasi bukti pelanggan
//   /// PUT /admin/payments/{id}/verify
//   /// ============================================================
//   static Future<bool> verifyCustomerProof({
//     required int paymentId,
//     required String action, // 'approve' | 'reject'
//     String? note,
//   }) async {
//     try {
//       final response = await ApiService.put(
//         '/admin/payments/$paymentId/verify',
//         {
//           'action': action,
//           if (note != null && note.isNotEmpty) 'note': note,
//         },
//       );
//       return response.statusCode == 200;
//     } catch (e) {
//       print('❌ PaymentService.verifyCustomerProof: $e');
//       return false;
//     }
//   }

//   /// ============================================================
//   /// ADMIN — Transfer ke mitra + upload bukti
//   /// POST /admin/payments/{id}/settle
//   /// ============================================================
//   static Future<bool> settleToMitra({
//     required int paymentId,
//     required Uint8List imageBytes,
//     String? note,
//   }) async {
//     try {
//       final response = await ApiService.postMultipart(
//         '/admin/payments/$paymentId/settle',
//         {
//           if (note != null && note.isNotEmpty) 'note': note,
//         },
//         files: {
//           'mitra_proof': imageBytes,
//         },
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       print('❌ PaymentService.settleToMitra: $e');
//       return false;
//     }
//   }

//   /// ============================================================
//   /// ADMIN — Refund
//   /// PUT /admin/payments/{id}/refund
//   /// ============================================================
//   static Future<bool> refund({
//     required int paymentId,
//     required String reason,
//   }) async {
//     try {
//       final response = await ApiService.put(
//         '/admin/payments/$paymentId/refund',
//         {'reason': reason},
//       );
//       return response.statusCode == 200;
//     } catch (e) {
//       print('❌ PaymentService.refund: $e');
//       return false;
//     }
//   }
// }

// lib/services/payment_service.dart

import 'dart:convert';
import 'dart:typed_data';

import 'api_service.dart';

// ============================================================
// ✅ CLASS UploadResult (dipakai untuk method yang upload file)
// ============================================================
class UploadResult {
  final bool success;
  final String? message;

  const UploadResult({
    required this.success,
    this.message,
  });

  static const UploadResult ok = UploadResult(success: true);

  factory UploadResult.fail(String message) {
    return UploadResult(success: false, message: message);
  }
}

class PaymentService {
  // ============================================================
  // PELANGGAN — Ambil detail pembayaran
  // ============================================================
  static Future<Map<String, dynamic>?> getPelangganPaymentDetail(int id) async {
    try {
      final response = await ApiService.get('/pelanggan/payments/$id');
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded['success'] != true) return null;

      return Map<String, dynamic>.from(decoded['data']);
    } catch (e) {
      print('❌ PaymentService.getPelangganPaymentDetail: $e');
      return null;
    }
  }

  // ============================================================
  // PELANGGAN — Upload bukti transfer
  // ============================================================
  static Future<UploadResult> uploadCustomerProof({
    required int paymentId,
    required Uint8List imageBytes,
    String? imageName,
    required String bankName,
    required String accountName,
    String? note,
  }) async {
    try {
      final response = await ApiService.postMultipart(
        '/pelanggan/payments/$paymentId/upload-proof',
        {
          'bank_name': bankName,
          'account_name': accountName,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        files: {
          'proof': imageBytes,
        },
      );

      print('📤 UPLOAD PROOF: ${response.statusCode}');
      print('📤 BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UploadResult.ok;
      }

      return UploadResult.fail(_parseErrorMessage(response));
    } catch (e) {
      print('❌ PaymentService.uploadCustomerProof: $e');
      return UploadResult.fail('Tidak dapat terhubung ke server.');
    }
  }

  // ============================================================
  // ADMIN — Ambil detail pembayaran
  // ============================================================
  static Future<Map<String, dynamic>?> getAdminPaymentDetail(int id) async {
    try {
      final response = await ApiService.get('/admin/payments/$id');
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded['success'] != true) return null;

      return Map<String, dynamic>.from(decoded['data']);
    } catch (e) {
      print('❌ PaymentService.getAdminPaymentDetail: $e');
      return null;
    }
  }

  // ============================================================
  // ADMIN — Verifikasi bukti pelanggan
  // ============================================================
  static Future<UploadResult> verifyCustomerProof({
    required int paymentId,
    required String action,
    String? note,
  }) async {
    try {
      final response = await ApiService.put(
        '/admin/payments/$paymentId/verify',
        {
          'action': action,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );

      print('📤 VERIFY: ${response.statusCode}');
      print('📤 BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UploadResult.ok;
      }

      return UploadResult.fail(_parseErrorMessage(response));
    } catch (e) {
      print('❌ PaymentService.verifyCustomerProof: $e');
      return UploadResult.fail('Tidak dapat terhubung ke server.');
    }
  }

  // ============================================================
  // ADMIN — Transfer ke mitra + upload bukti
  // ============================================================
  static Future<UploadResult> settleToMitra({
    required int paymentId,
    required Uint8List imageBytes,
    String? imageName,
    String? note,
  }) async {
    try {
      final response = await ApiService.postMultipart(
        '/admin/payments/$paymentId/settle',
        {
          if (note != null && note.isNotEmpty) 'note': note,
        },
        files: {
          'mitra_proof': imageBytes,
        },
      );

      print('📤 SETTLE: ${response.statusCode}');
      print('📤 BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UploadResult.ok;
      }

      return UploadResult.fail(_parseErrorMessage(response));
    } catch (e) {
      print('❌ PaymentService.settleToMitra: $e');
      return UploadResult.fail('Tidak dapat terhubung ke server.');
    }
  }

  // ============================================================
  // ✅ ADMIN — Refund (INI YANG HILANG)
  // ============================================================
  static Future<UploadResult> refund({
    required int paymentId,
    required String reason,
  }) async {
    try {
      final response = await ApiService.put(
        '/admin/payments/$paymentId/refund',
        {'reason': reason},
      );

      print('📤 REFUND: ${response.statusCode}');
      print('📤 BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UploadResult.ok;
      }

      return UploadResult.fail(_parseErrorMessage(response));
    } catch (e) {
      print('❌ PaymentService.refund: $e');
      return UploadResult.fail('Tidak dapat terhubung ke server.');
    }
  }

  // ============================================================
  // PELANGGAN — Cek status rating untuk job
  // ============================================================
  static Future<Map<String, dynamic>?> checkJobRating(int jobId) async {
    try {
      final response = await ApiService.get('/pelanggan/ratings/job/$jobId');
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded['success'] != true) return null;

      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      print('❌ PaymentService.checkJobRating: $e');
      return null;
    }
  }

  // ============================================================
  // PELANGGAN — Kirim rating
  // ============================================================
  static Future<Map<String, dynamic>?> submitRating({
    required int jobId,
    required int stars,
    String? comment,
  }) async {
    try {
      final response = await ApiService.post(
        '/pelanggan/ratings',
        {
          'job_id': jobId,
          'stars': stars,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 201 && decoded['success'] == true) {
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    } catch (e) {
      print('❌ PaymentService.submitRating: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ HELPER: Parse pesan error dari response Laravel
  // ============================================================
  static String _parseErrorMessage(dynamic response) {
    String errorMessage = 'Gagal memproses. Coba lagi.';

    try {
      final errorData = jsonDecode(response.body);

      // Format validasi Laravel: { "errors": { "field": ["pesan"] } }
      if (errorData is Map && errorData['errors'] is Map) {
        final errors = errorData['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstKey = errors.keys.first;
          if (errors[firstKey] is List &&
              (errors[firstKey] as List).isNotEmpty) {
            errorMessage = (errors[firstKey] as List)[0].toString();
          }
        }
      }
      // Format umum: { "message": "..." }
      else if (errorData is Map && errorData['message'] != null) {
        errorMessage = errorData['message'].toString();
      }
    } catch (_) {
      // Fallback generic berdasarkan status code
      switch (response.statusCode) {
        case 422:
          errorMessage = 'Data tidak valid. Periksa kembali.';
          break;
        case 401:
          errorMessage = 'Sesi login berakhir. Silakan login ulang.';
          break;
        case 413:
          errorMessage = 'File terlalu besar untuk server.';
          break;
        case 500:
          errorMessage = 'Terjadi kesalahan di server.';
          break;
      }
    }

    return errorMessage;
  }
}