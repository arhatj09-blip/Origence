import 'dart:io' show Platform;

String getApiBaseUrlImpl() {
  if (Platform.isAndroid) {
    return 'http://192.168.1.11:8000/api/';
  }
  return 'http://127.0.0.1:8000/api/';
}
