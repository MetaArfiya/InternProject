// lib/services/payment_service.dart

import 'dart:convert';
import 'dart:typed_data';

import 'api_service.dart';

class PaymentService {
  /// ============================================================
  /// PELANGGAN — Ambil detail pembayaran + info rekening platform
  /// GET /pelanggan/payments/{id}
  /// ============================================================
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

  /// ============================================================
  /// PELANGGAN — Upload bukti transfer
  /// POST /pelanggan/payments/{id}/upload-proof
  /// ============================================================
  static Future<bool> uploadCustomerProof({
    required int paymentId,
    required Uint8List imageBytes,
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

      return response.statusCode == 200;
    } catch (e) {
      print('❌ PaymentService.uploadCustomerProof: $e');
      return false;
    }
  }

  /// ============================================================
  /// ADMIN — Ambil detail pembayaran + rekening mitra
  /// GET /admin/payments/{id}
  /// ============================================================
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

  /// ============================================================
  /// ADMIN — Verifikasi bukti pelanggan
  /// PUT /admin/payments/{id}/verify
  /// ============================================================
  static Future<bool> verifyCustomerProof({
    required int paymentId,
    required String action, // 'approve' | 'reject'
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
      return response.statusCode == 200;
    } catch (e) {
      print('❌ PaymentService.verifyCustomerProof: $e');
      return false;
    }
  }

  /// ============================================================
  /// ADMIN — Transfer ke mitra + upload bukti
  /// POST /admin/payments/{id}/settle
  /// ============================================================
  static Future<bool> settleToMitra({
    required int paymentId,
    required Uint8List imageBytes,
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

      return response.statusCode == 200;
    } catch (e) {
      print('❌ PaymentService.settleToMitra: $e');
      return false;
    }
  }

  /// ============================================================
  /// ADMIN — Refund
  /// PUT /admin/payments/{id}/refund
  /// ============================================================
  static Future<bool> refund({
    required int paymentId,
    required String reason,
  }) async {
    try {
      final response = await ApiService.put(
        '/admin/payments/$paymentId/refund',
        {'reason': reason},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ PaymentService.refund: $e');
      return false;
    }
  }
}