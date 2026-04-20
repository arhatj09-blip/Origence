import 'api_host_web.dart' if (dart.library.io) 'api_host_io.dart';

String getApiBaseUrl() => getApiBaseUrlImpl();
