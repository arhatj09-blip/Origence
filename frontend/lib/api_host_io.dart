import 'dart:io' show Platform;

String getApiBaseUrlImpl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api/';
  }
  return 'http://127.0.0.1:8000/api/';
}
