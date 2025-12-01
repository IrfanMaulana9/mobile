import 'location_history.dart';

class ExperimentSession {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int intervalSeconds;
  final List<LocationHistoryEntry> gpsData;
  final List<LocationHistoryEntry> networkData;
  final Map<String, dynamic> metadata;

  ExperimentSession({
    required this.id,
    required this.name,
    required this.createdAt,
    this.completedAt,
    required this.intervalSeconds,
    this.gpsData = const [],
    this.networkData = const [],
    this.metadata = const {},
  });

  int get totalRecords => gpsData.length + networkData.length;
  
  double get gpsAverageAccuracy {
    if (gpsData.isEmpty) return 0;
    return gpsData.fold(0.0, (sum, entry) => sum + entry.accuracy) / gpsData.length;
  }

  double get networkAverageAccuracy {
    if (networkData.isEmpty) return 0;
    return networkData.fold(0.0, (sum, entry) => sum + entry.accuracy) / networkData.length;
  }

  double get accuracyDifference => (gpsAverageAccuracy - networkAverageAccuracy).abs();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'intervalSeconds': intervalSeconds,
      'gpsData': gpsData.map((e) => e.toMap()).toList(),
      'networkData': networkData.map((e) => e.toMap()).toList(),
      'metadata': metadata,
    };
  }

  factory ExperimentSession.fromMap(Map<String, dynamic> map) {
    return ExperimentSession(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      intervalSeconds: map['intervalSeconds'],
      gpsData: List<LocationHistoryEntry>.from(
        (map['gpsData'] as List).map((e) => LocationHistoryEntry.fromMap(e)),
      ),
      networkData: List<LocationHistoryEntry>.from(
        (map['networkData'] as List).map((e) => LocationHistoryEntry.fromMap(e)),
      ),
      metadata: map['metadata'] ?? {},
    );
  }
}
