import 'dart:io' show Platform;

String getApiBaseUrlImpl() {
  // PRODUCTION: Change this to your Railway URL
  // const String productionUrl = 'https://your-app-name.railway.app/api/';
  
  // Development URLs
  if (Platform.isAndroid) {
    return 'http://192.168.1.11:8000/api/';
  }
  return 'http://127.0.0.1:8000/api/';
  
  // Uncomment below for production (replace with your Railway URL)
  // return productionUrl;
}
