/// Model untuk tracking performa setiap operasi storage
class StoragePerformanceLog {
  final String operation; // 'read' atau 'write'
  final String storageType; // 'prefs', 'hive', 'supabase'
  final String dataKey;
  final int executionTimeMs;
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;

  StoragePerformanceLog({
    required this.operation,
    required this.storageType,
    required this.dataKey,
    required this.executionTimeMs,
    required this.success,
    this.errorMessage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'storageType': storageType,
    'dataKey': dataKey,
    'executionTimeMs': executionTimeMs,
    'success': success,
    'errorMessage': errorMessage,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() => 'StoragePerformanceLog('
      'operation: $operation, '
      'storageType: $storageType, '
      'dataKey: $dataKey, '
      'executionTimeMs: ${executionTimeMs}ms, '
      'success: $success, '
      'timestamp: $timestamp)';
}

/// Service untuk mencatat performa dan eksport report
class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  
  factory PerformanceTracker() {
    return _instance;
  }
  
  PerformanceTracker._internal();
  
  final List<StoragePerformanceLog> _logs = [];
  
  void addLog(StoragePerformanceLog log) {
    _logs.add(log);
    print('[PERF] ${log.toString()}');
  }
  
  List<StoragePerformanceLog> getLogs({String? storageType, String? operation}) {
    return _logs.where((log) {
      if (storageType != null && log.storageType != storageType) return false;
      if (operation != null && log.operation != operation) return false;
      return true;
    }).toList();
  }
  
  Map<String, dynamic> getPerformanceReport() {
    final prefs = _logs.where((l) => l.storageType == 'prefs').toList();
    final hive = _logs.where((l) => l.storageType == 'hive').toList();
    final supabase = _logs.where((l) => l.storageType == 'supabase').toList();
    
    return {
      'totalOperations': _logs.length,
      'prefs': {
        'total': prefs.length,
        'avgTime': prefs.isEmpty ? 0 : prefs.map((l) => l.executionTimeMs).reduce((a, b) => a + b) ~/ prefs.length,
        'successRate': prefs.isEmpty ? 0 : (prefs.where((l) => l.success).length / prefs.length * 100).toStringAsFixed(2) + '%',
      },
      'hive': {
        'total': hive.length,
        'avgTime': hive.isEmpty ? 0 : hive.map((l) => l.executionTimeMs).reduce((a, b) => a + b) ~/ hive.length,
        'successRate': hive.isEmpty ? 0 : (hive.where((l) => l.success).length / hive.length * 100).toStringAsFixed(2) + '%',
      },
      'supabase': {
        'total': supabase.length,
        'avgTime': supabase.isEmpty ? 0 : supabase.map((l) => l.executionTimeMs).reduce((a, b) => a + b) ~/ supabase.length,
        'successRate': supabase.isEmpty ? 0 : (supabase.where((l) => l.success).length / supabase.length * 100).toStringAsFixed(2) + '%',
      },
      'allLogs': _logs.map((l) => l.toJson()).toList(),
    };
  }
  
  void clearLogs() => _logs.clear();
}
