import 'dart:typed_data';

// Stub used on non-web platforms. Should not be called.
Future<Map<String, dynamic>> webUploadRaw(
  String url,
  String username,
  Uint8List fileBytes,
  String filename,
) async {
  throw UnsupportedError('webUploadRaw should only be used on web platforms');
}
