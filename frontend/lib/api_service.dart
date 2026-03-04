import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use localhost for web; 10.0.2.2 for Android emulator
  static String get _baseUrl =>
      kIsWeb ? 'http://localhost:8000/api/' : 'http://10.0.2.2:8000/api/';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // ---------- Register ----------
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = '${_baseUrl}register/';
    final body = jsonEncode({
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
    });

    debugPrint('[API] POST $url');
    debugPrint('[API] Body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );

      debugPrint('[API] Status: ${response.statusCode}');
      debugPrint('[API] Response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ---------- Login ----------
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = '${_baseUrl}login/';
    final body = jsonEncode({'username': username, 'password': password});

    debugPrint('[API] POST $url');
    debugPrint('[API] Body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );

      debugPrint('[API] Status: ${response.statusCode}');
      debugPrint('[API] Response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Save username locally on successful login
      if (data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', data['username'] ?? '');
      }

      return data;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ---------- Logout ----------
  static Future<Map<String, dynamic>> logout() async {
    final url = '${_baseUrl}logout/';

    debugPrint('[API] POST $url');

    try {
      final response = await http.post(Uri.parse(url), headers: _headers);

      debugPrint('[API] Status: ${response.statusCode}');
      debugPrint('[API] Response: ${response.body}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      // Even if server call fails, clear local state
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return {'status': 'success', 'message': 'Logged out locally'};
    }
  }

  // ---------- Upload Document ----------
  // filePath: local path of the file to upload
  static Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String username,
  }) async {
    final url = '${_baseUrl}upload-document/';

    debugPrint('[API] UPLOAD $url');
    debugPrint('[API] filePath: $filePath');

    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      // include username so backend can associate file with user
      request.fields['username'] = username;

      final multipartFile = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[API] Status: ${response.statusCode}');
      debugPrint('[API] Response: ${response.body}');

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] UPLOAD ERROR: $e');
      return {'status': 'error', 'message': 'Upload failed: $e'};
    }
  }

  // ---------- Helpers ----------
  static Future<String?> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('username');
  }
}
