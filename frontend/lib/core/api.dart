import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  /// Override at build time: flutter run --dart-define=API_URL=https://your-api.onrender.com/api
  static String get baseUrl {
    const env = String.fromEnvironment('API_URL');
    if (env.isNotEmpty) return env;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api'; // Android emulator -> your PC
    }
    return 'http://localhost:4000/api';
  }

  static String? token;

  static Future<void> loadToken() async {
    token = (await SharedPreferences.getInstance()).getString('token');
  }

  static Future<void> saveToken(String? t) async {
    token = t;
    final p = await SharedPreferences.getInstance();
    t == null ? await p.remove('token') : await p.setString('token', t);
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic _handle(http.Response r) {
    dynamic body;
    try {
      body = r.body.isEmpty ? null : jsonDecode(r.body);
    } catch (_) {}
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    throw ApiException(body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Request failed (${r.statusCode})');
  }

  static Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      return _handle(await call().timeout(const Duration(seconds: 20)));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot reach server. Check your connection / API URL.');
    }
  }

  static Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => http.get(Uri.parse('$baseUrl$path').replace(queryParameters: query), headers: _headers));
  static Future<dynamic> post(String path, Map body) =>
      _send(() => http.post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body)));
  static Future<dynamic> put(String path, Map body) =>
      _send(() => http.put(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body)));
  static Future<dynamic> delete(String path) =>
      _send(() => http.delete(Uri.parse('$baseUrl$path'), headers: _headers));
}
