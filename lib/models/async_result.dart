class AsyncResult {
  final String methodName; // 'async-await' atau 'callback'
  final int totalTime; // dalam milliseconds
  final String weatherData;
  final String recommendation;
  final DateTime timestamp;
  final String? errorMessage;

  AsyncResult({
    required this.methodName,
    required this.totalTime,
    required this.weatherData,
    required this.recommendation,
    required this.timestamp,
    this.errorMessage,
  });

  @override
  String toString() =>
      'AsyncResult(method: $methodName, time: ${totalTime}ms, weather: $weatherData)';
}
