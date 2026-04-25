import 'package:dio/dio.dart';
import 'token_store.dart';

// Android emulator → 10.0.2.2, iOS simulator / web → 127.0.0.1
// Change to your machine's LAN IP when testing on a real device.
const String kBaseUrl = 'http://10.0.2.2:8000/api';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStore.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

  static Dio get instance => _dio;

  static String extractError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data.containsKey('detail')) return data['detail'].toString();
        if (data.containsKey('error')) return data['error'].toString();
        if (data.containsKey('message')) return data['message'].toString();
        final firstKey = data.keys.first;
        final val = data[firstKey];
        if (val is List && val.isNotEmpty) return val.first.toString();
      }
      return error.message ?? 'Something went wrong.';
    }
    return error.toString();
  }
}
