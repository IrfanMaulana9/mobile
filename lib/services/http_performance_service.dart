import 'package:http/http.dart' as http;
import '../models/performance_result.dart';

class HttpPerformanceService {
  static const String baseUrl = 'https://api.open-meteo.com/v1';

  Future<PerformanceResult> fetchWeatherWithHttp({
    required double latitude,
    required double longitude,
  }) async {
    final stopwatch = Stopwatch()..start();
    final endpoint = '$baseUrl/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m';

    try {
      final response = await http.get(Uri.parse(endpoint)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('HTTP Request Timeout'),
      );

      stopwatch.stop();

      return PerformanceResult(
        libraryName: 'http',
        responseTime: stopwatch.elapsedMilliseconds,
        statusCode: response.statusCode,
        timestamp: DateTime.now(),
        endpoint: endpoint,
        errorMessage: response.statusCode != 200 ? 'Status: ${response.statusCode}' : null,
      );
    } catch (e) {
      stopwatch.stop();
      return PerformanceResult(
        libraryName: 'http',
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
      final result = await fetchWeatherWithHttp(latitude: latitude, longitude: longitude);
      results.add(result);
      await Future.delayed(const Duration(milliseconds: 500)); // Delay antar request
    }

    return results;
  }
}
