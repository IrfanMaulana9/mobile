class PerformanceResult {
  final String libraryName;
  final int responseTime; // dalam milliseconds
  final int statusCode;
  final String? errorMessage;
  final DateTime timestamp;
  final String endpoint;

  PerformanceResult({
    required this.libraryName,
    required this.responseTime,
    required this.statusCode,
    this.errorMessage,
    required this.timestamp,
    required this.endpoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'libraryName': libraryName,
      'responseTime': responseTime,
      'statusCode': statusCode,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'endpoint': endpoint,
    };
  }

  @override
  String toString() =>
      'PerformanceResult(library: $libraryName, time: ${responseTime}ms, status: $statusCode)';
}

class PerformanceStats {
  final List<PerformanceResult> results;

  PerformanceStats({required this.results});

  double get averageResponseTime =>
      results.isEmpty ? 0 : results.map((r) => r.responseTime).reduce((a, b) => a + b) / results.length;

  int get fastestResponseTime => results.isEmpty ? 0 : results.map((r) => r.responseTime).reduce((a, b) => a < b ? a : b);

  int get slowestResponseTime => results.isEmpty ? 0 : results.map((r) => r.responseTime).reduce((a, b) => a > b ? a : b);

  int get successCount => results.where((r) => r.statusCode == 200).length;

  int get errorCount => results.where((r) => r.statusCode != 200).length;

  double get successRate => results.isEmpty ? 0 : (successCount / results.length) * 100;
}
