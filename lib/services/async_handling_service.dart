import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/async_result.dart';

class AsyncHandlingService {
  static const String weatherUrl = 'https://api.open-meteo.com/v1/forecast?latitude=-6.2088&longitude=106.8456&current=temperature_2m,weather_code,relative_humidity_2m&timezone=auto';

  Future<AsyncResult> fetchWeatherAndRecommendationAsyncAwait() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Fetch weather data
      print('[AsyncAwait] Fetching weather data...');
      final weatherResponse = await http.get(Uri.parse(weatherUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (weatherResponse.statusCode != 200) {
        throw Exception('Failed to fetch weather: ${weatherResponse.statusCode} - ${weatherResponse.body}');
      }

      final weatherData = jsonDecode(weatherResponse.body);
      
      final current = weatherData['current'];
      final temperature = current['temperature_2m'] ?? 0.0;
      final weatherCode = current['weather_code'] ?? 0;
      final humidity = current['relative_humidity_2m'] ?? 0;

      print('[AsyncAwait] Weather fetched: Temp=$temperature°C, Code=$weatherCode');

      // Step 2: Generate recommendation based on weather
      print('[AsyncAwait] Generating recommendation...');
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate processing

      String recommendation = _getCleaningRecommendation(temperature, weatherCode, humidity);

      stopwatch.stop();

      return AsyncResult(
        methodName: 'async-await',
        totalTime: stopwatch.elapsedMilliseconds,
        weatherData: 'Temp: $temperature°C, Code: $weatherCode, Humidity: $humidity%',
        recommendation: recommendation,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      print('[AsyncAwait] Error: $e');
      return AsyncResult(
        methodName: 'async-await',
        totalTime: stopwatch.elapsedMilliseconds,
        weatherData: 'Error',
        recommendation: 'Error',
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  Future<AsyncResult> fetchWeatherAndRecommendationCallback() async {
    final stopwatch = Stopwatch()..start();

    return Future(() {
      print('[Callback] Fetching weather data...');
      return http.get(Uri.parse(weatherUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );
    }).then((weatherResponse) {
      if (weatherResponse.statusCode != 200) {
        throw Exception('Failed to fetch weather: ${weatherResponse.statusCode} - ${weatherResponse.body}');
      }

      final weatherData = jsonDecode(weatherResponse.body);
      
      final current = weatherData['current'];
      final temperature = current['temperature_2m'] ?? 0.0;
      final weatherCode = current['weather_code'] ?? 0;
      final humidity = current['relative_humidity_2m'] ?? 0;

      print('[Callback] Weather fetched: Temp=$temperature°C, Code=$weatherCode');

      // Nested callback untuk processing
      return Future.delayed(const Duration(milliseconds: 300)).then((_) {
        print('[Callback] Generating recommendation...');
        String recommendation = _getCleaningRecommendation(temperature, weatherCode, humidity);

        stopwatch.stop();

        return AsyncResult(
          methodName: 'callback',
          totalTime: stopwatch.elapsedMilliseconds,
          weatherData: 'Temp: $temperature°C, Code: $weatherCode, Humidity: $humidity%',
          recommendation: recommendation,
          timestamp: DateTime.now(),
        );
      });
    }).catchError((e) {
      stopwatch.stop();
      print('[Callback] Error: $e');
      return AsyncResult(
        methodName: 'callback',
        totalTime: stopwatch.elapsedMilliseconds,
        weatherData: 'Error',
        recommendation: 'Error',
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    });
  }

  String _getCleaningRecommendation(double temperature, int weatherCode, int humidity) {
    if (weatherCode == 0 || weatherCode == 1) {
      return 'Cuaca cerah - Rekomendasikan layanan outdoor cleaning (jendela, fasad)';
    } else if (weatherCode >= 2 && weatherCode <= 3) {
      return 'Cuaca berawan - Layanan indoor cleaning cocok dilakukan';
    } else if (weatherCode >= 45 && weatherCode <= 48) {
      return 'Berkabut - Tunda outdoor cleaning, fokus indoor';
    } else if (weatherCode >= 51 && weatherCode <= 67) {
      return 'Hujan - Prioritaskan indoor cleaning dan waterproofing check';
    } else if (weatherCode >= 80 && weatherCode <= 82) {
      return 'Hujan lebat - Layanan emergency cleaning untuk area terdampak';
    } else {
      return 'Kondisi cuaca ekstrem - Konsultasi dengan tim profesional';
    }
  }
}
