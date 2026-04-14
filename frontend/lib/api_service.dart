import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_host.dart';

class ApiService {
  static String get _baseUrl => getApiBaseUrl();

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // ---------- Register ----------
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String role,
  }) async {
    final url = '${_baseUrl}register/';
    final body = jsonEncode({
      'username': username,
      'password': password,
      'confirm_password': password,
      'role': role,
    });

    debugPrint('[API] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
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
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', data['username'] ?? '');
        await prefs.setString('role', data['role'] ?? '');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return {'status': 'success', 'message': 'Logged out locally'};
    }
  }

  // ---------- Create Batch (Faculty) ----------
  static Future<Map<String, dynamic>> createBatch({
    required String username,
    required String batchName,
    required String batchCode,
    double? similarityThreshold,
  }) async {
    final url = '${_baseUrl}create-batch/';
    final body = jsonEncode({
      'username': username,
      'batch_name': batchName,
      'batch_code': batchCode,
      if (similarityThreshold != null)
        'similarity_threshold': similarityThreshold,
    });
    debugPrint('[API] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ---------- Get Batches (Faculty) ----------
  static Future<Map<String, dynamic>> getBatches({
    required String username,
  }) async {
    final url = '${_baseUrl}get-batches/';
    final body = jsonEncode({'username': username});
    debugPrint('[API] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ---------- Set Batch Threshold (Faculty) ----------
  static Future<Map<String, dynamic>> setBatchThreshold({
    required String username,
    required int batchId,
    required double similarityThreshold,
  }) async {
    final url = '${_baseUrl}set-batch-threshold/';
    final body = jsonEncode({
      'username': username,
      'batch_id': batchId,
      'similarity_threshold': similarityThreshold,
    });
    debugPrint('[API] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ---------- Join Batch (Student) ----------
  static Future<Map<String, dynamic>> joinBatch({
    required String username,
    required String batchCode,
  }) async {
    final url = '${_baseUrl}join-batch/';
    final body = jsonEncode({'username': username, 'batch_code': batchCode});
    debugPrint('[API] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ---------- Get Student's Joined Batches ----------
  static Future<Map<String, dynamic>> getStudentBatches({
    required String username,
  }) async {
    final url = '${_baseUrl}get-student-batches/';
    final body = jsonEncode({'username': username});
    debugPrint('[API] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ---------- Upload Document ----------
  static Future<Map<String, dynamic>> uploadDocument({
    String? filePath,
    Uint8List? fileBytes,
    String? filename,
    required String username,
    required int batchId,
  }) async {
    final url = '${_baseUrl}upload-document/';
    debugPrint('[API] UPLOAD $url  batch=$batchId');
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      request.fields['username'] = username;
      request.fields['batch_id'] = batchId.toString();

      if (kIsWeb) {
        if (fileBytes == null || filename == null) {
          return {
            'status': 'error',
            'message': 'On web provide fileBytes and filename.',
          };
        }
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
        );
      } else {
        if (filePath == null) {
          return {
            'status': 'error',
            'message': 'filePath is required on non-web platforms.',
          };
        }
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      debugPrint('[API] ${response.statusCode} ${response.body}');
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

  static Future<String?> getLoggedInRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('username');
  }

  // ---------- Get Batch Documents ----------
  static Future<Map<String, dynamic>> getBatchDocuments({
    required int batchId,
  }) async {
    final url = '${_baseUrl}get-batch-documents/';
    final body = jsonEncode({'batch_id': batchId.toString()});
    debugPrint('[API] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ---------- Upload Document (Batch-Specific) ----------
  static Future<Map<String, dynamic>> uploadDocumentToBatch({
    String? filePath,
    Uint8List? fileBytes,
    String? filename,
    required String username,
    required int batchId,
  }) async {
    final url = '${_baseUrl}upload-document/';
    debugPrint('[API] UPLOAD $url batch=$batchId');
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      request.fields['username'] = username;
      request.fields['batch_id'] = batchId.toString();

      if (kIsWeb) {
        if (fileBytes == null || filename == null) {
          return {
            'status': 'error',
            'message': 'On web provide fileBytes and filename.',
          };
        }
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
        );
      } else {
        if (filePath == null) {
          return {
            'status': 'error',
            'message': 'filePath is required on non-web platforms.',
          };
        }
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] UPLOAD ERROR: $e');
      return {'status': 'error', 'message': 'Upload failed: $e'};
    }
  }

  // ---------- Get Batch Details with Students and Document Status (Faculty) ----------
  static Future<Map<String, dynamic>> getBatchDetails({
    required String username,
    required int batchId,
  }) async {
    final url = '${_baseUrl}get-batch-details/';
    final body = jsonEncode({'username': username, 'batch_id': batchId});
    debugPrint('[API] POST $url batch_id=$batchId');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      debugPrint('[API] ${response.statusCode} ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }
}
