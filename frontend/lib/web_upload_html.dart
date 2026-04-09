import 'dart:typed_data';
import 'dart:html' as html;

// Sends FormData via browser HttpRequest and returns a raw map with statusCode/body
Future<Map<String, dynamic>> webUploadRaw(
  String url,
  String username,
  Uint8List fileBytes,
  String filename,
) async {
  final form = html.FormData();
  final blob = html.Blob([fileBytes]);
  form.appendBlob('file', blob, filename);
  form.append('username', username);

  final req = await html.HttpRequest.request(
    url,
    method: 'POST',
    sendData: form,
  );

  final status = req.status ?? 0;
  final body = req.responseText ?? '';

  return {'statusCode': status, 'body': body};
}
