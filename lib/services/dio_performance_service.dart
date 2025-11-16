import 'package:dio/dio.dart';
import '../models/performance_result.dart';

class DioPerformanceService {
  static const String baseUrl = 'https://api.open-meteo.com/v1';
  late Dio _dio;

  DioPerformanceService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      LoggingInterceptor(),
    );
  }

  Future<PerformanceResult> fetchWeatherWithDio({
    required double latitude,
    required double longitude,
  }) async {
    final stopwatch = Stopwatch()..start();
    final endpoint = '/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m';

    try {
      final response = await _dio.get(endpoint);

      stopwatch.stop();

      return PerformanceResult(
        libraryName: 'Dio',
        responseTime: stopwatch.elapsedMilliseconds,
        statusCode: response.statusCode ?? 0,
        timestamp: DateTime.now(),
        endpoint: endpoint,
        errorMessage: response.statusCode != 200 ? 'Status: ${response.statusCode}' : null,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      return PerformanceResult(
        libraryName: 'Dio',
        responseTime: stopwatch.elapsedMilliseconds,
        statusCode: 0,
        timestamp: DateTime.now(),
        endpoint: endpoint,
        errorMessage: 'DioException: ${e.message}',
      );
    } catch (e) {
      stopwatch.stop();
      return PerformanceResult(
        libraryName: 'Dio',
        responseTime: stopwatch.elapsedMilliseconds,
        statusCode: 0,
        timestamp: DateTime.now(),
        endpoint: endpoint,
        errorMessage: e.toString(),
      );
    }
  }

  Future<List<PerformanceResult>> runMultipleTests({
    required int iterations,
    required double latitude,
    required double longitude,
  }) async {
    final results = <PerformanceResult>[];

    for (int i = 0; i < iterations; i++) {
      final result = await fetchWeatherWithDio(latitude: latitude, longitude: longitude);
      results.add(result);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('[Dio] REQUEST: ${options.method} ${options.path}');
    print('[Dio] Headers: ${options.headers}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[Dio] RESPONSE: ${response.statusCode} - ${response.requestOptions.path}');
    print('[Dio] Data length: ${response.data.toString().length} bytes');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('[Dio] ERROR: ${err.message}');
    print('[Dio] Error type: ${err.type}');
    super.onError(err, handler);
  }
}
