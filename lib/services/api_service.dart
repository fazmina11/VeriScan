import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.221.44:8000';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    // Attach Bearer token to every outgoing request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. login
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['access_token'] as String;
      final userData = response.data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(
        key: 'user_data',
        value: jsonEncode(userData),
      );

      return userData;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw 'Cannot connect to server.\nCheck WiFi connection.';
      }
      final detail = e.response?.data?['detail'];
      if (detail != null) throw detail.toString();
      throw 'Login failed. Please try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. register
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? labName,
    String? employeeId,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role,
          'lab_name': labName ?? '',
          'employee_id': employeeId ?? '',
        },
      );

      final token = response.data['access_token'] as String;
      final userData = response.data['user'] as Map<String, dynamic>;

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(
        key: 'user_data',
        value: jsonEncode(userData),
      );

      return userData;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw 'Cannot connect to server.\nCheck WiFi connection.';
      }
      final detail = e.response?.data?['detail'];
      if (detail != null) throw detail.toString();
      throw 'Registration failed. Please try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. logout
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. isLoggedIn
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. getCurrentUser
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData == null) return null;
    return jsonDecode(userData) as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. predictScan
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> predictScan({
    required List<double> spectralValues,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/scan/predict',
        data: {'values': spectralValues},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw 'Cannot connect to server.\nCheck WiFi connection.';
      }
      final detail = e.response?.data?['detail'];
      if (detail != null) throw detail.toString();
      throw 'Scan prediction failed. Please try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. saveScan
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> saveScan({
    required String resultCode,
    required double similarityScore,
    required double aiConfidence,
    required String geminiReport,
    required String medicineName,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/scan/save',
        data: {
          'result_code': resultCode,
          'similarity_score': similarityScore,
          'ai_confidence': aiConfidence,
          'gemini_report': geminiReport,
          'medicine_name': medicineName,
        },
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw 'Cannot connect to server.\nCheck WiFi connection.';
      }
      final detail = e.response?.data?['detail'];
      if (detail != null) throw detail.toString();
      throw 'Failed to save scan. Please try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. getScanHistory
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getScanHistory() async {
    try {
      final response = await _dio.get('$_baseUrl/scan/history');
      final data = response.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(),
);
