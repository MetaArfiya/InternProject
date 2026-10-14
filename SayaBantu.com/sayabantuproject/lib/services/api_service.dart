import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// import 'package:shared_preferences/shared_preferences.dart';
import 'auth_storage.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  // Flutter Web:
  // http://localhost:8000/api

  // Android Emulator:
  // http://10.0.2.2:8000/api

  static const String baseUrl = 'http://localhost:8000/api';

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> _getToken() async {
    return AuthStorage.getString('token');
  }

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    debugPrint("🔑 TOKEN DI API_SERVICE: '$token'");

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET
  // ============================================================

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();

    debugPrint('🌐 [GET] $url');

    final response = await http.get(url, headers: headers);

    debugPrint('🔎 [GET RESPONSE] ${response.statusCode} - $url');

    debugPrint('📦 BODY: ${response.body}');

    return response;
  }

  // ============================================================
  // POST
  // ============================================================

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();

    debugPrint('🌐 [POST] $url');
    debugPrint('📤 DATA: $data');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    debugPrint('🔎 [POST RESPONSE] ${response.statusCode} - $url');

    debugPrint('📦 BODY: ${response.body}');

    return response;
  }

  // ============================================================
  // PUT
  // ============================================================

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();

    debugPrint('🌐 [PUT] $url');
    debugPrint('📤 DATA: $data');

    try {
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      debugPrint('🔎 [PUT RESPONSE] ${response.statusCode} - $url');

      debugPrint('📦 BODY: ${response.body}');

      return response;
    } catch (e) {
      debugPrint('❌ [PUT ERROR] $e');
      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();

    debugPrint('🌐 [DELETE] $url');

    final response = await http.delete(url, headers: headers);

    debugPrint('🔎 [DELETE RESPONSE] ${response.statusCode} - $url');

    debugPrint('📦 BODY: ${response.body}');

    return response;
  }

  // ============================================================
  // POST MULTIPART / UPLOAD FILE
  // ============================================================

  static Future<http.Response> postMultipart(
    String endpoint,
    Map<String, String> fields, {
    Map<String, Uint8List>? files,
    Map<String, List<Uint8List>>? multipleFiles,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final token = await _getToken();

    debugPrint('🌐 [POST MULTIPART] $url');
    debugPrint('📤 FIELDS: $fields');

    final request = http.MultipartRequest('POST', url);

    request.headers['Accept'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // FIELD TEXT
    request.fields.addAll(fields);

    // SINGLE FILE
    if (files != null) {
      for (final entry in files.entries) {
        request.files.add(
          http.MultipartFile.fromBytes(
            entry.key,
            entry.value,
            filename: _getFileName(entry.key),
          ),
        );
      }
    }

    // MULTIPLE FILE
    if (multipleFiles != null) {
      for (final entry in multipleFiles.entries) {
        for (int i = 0; i < entry.value.length; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              entry.key,
              entry.value[i],
              filename: '${entry.key.replaceAll('[]', '')}_$i.jpg',
            ),
          );
        }
      }
    }

    try {
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('🔎 [MULTIPART RESPONSE] ${response.statusCode} - $url');

      debugPrint('📦 BODY: ${response.body}');

      return response;
    } catch (e) {
      debugPrint('❌ [MULTIPART ERROR] $e');
      rethrow;
    }
  }

  // ============================================================
  // FILE NAME
  // ============================================================

  static String _getFileName(String fieldName) {
    switch (fieldName) {
      case 'ktp_image':
        return 'ktp.jpg';

      case 'verification_image':
        return 'verification.jpg';

      default:
        return 'image.jpg';
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<http.Response> register(
    String name,
    String email,
    String password,
    int roleId,
  ) async {
    return await post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'role_id': roleId,
    });
  }
}