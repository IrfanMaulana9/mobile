import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/experiment_session.dart';
import '../models/location_history.dart';
import '../services/hive_service.dart';
import 'gps_controller.dart';
import 'network_location_controller.dart';

class ExperimentController extends GetxController {
  static const String _logTag = '[ExperimentController]';

  late final GPSController gpsController;
  late final NetworkLocationController networkController;
  final hiveService = HiveService();

  // Current experiment session
  final currentSession = Rxn<ExperimentSession>();
  final isRecording = false.obs;
  final recordingProgress = 0.obs;
  final recordingMessage = ''.obs;
  final sessions = <ExperimentSession>[].obs;
  
  // Recording control
  Timer? _recordingTimer;
  int _recordCount = 0;

  @override
  Future<void> onInit() async {
    super.onInit();
    gpsController = Get.find<GPSController>();
    networkController = Get.find<NetworkLocationController>();
    
    await loadSessions();
    print('$_logTag Initialized with ${sessions.length} saved sessions');
  }

  /// Load all saved sessions from storage
  Future<void> loadSessions() async {
    try {
      // Sessions are stored in memory for this session. For persistence, create ExperimentSession Hive model separately
      print('$_logTag Loaded ${sessions.length} sessions from memory');
    } catch (e) {
      print('$_logTag Error loading sessions: $e');
      sessions.value = [];
    }
  }

  /// Create new experiment session
  Future<void> createSession({
    required String name,
    required int intervalSeconds,
  }) async {
    final session = ExperimentSession(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      intervalSeconds: intervalSeconds,
      gpsData: [],
      networkData: [],
      metadata: {
        'location': 'Pending',
        'weather': 'Clear',
        'signalStrength': 'Unknown',
      },
    );

    currentSession.value = session;
    _recordCount = 0;
    recordingProgress.value = 0;
    recordingMessage.value = 'Session created. Ready to record.';
    
    print('$_logTag New session created: ${session.name}');
    Get.snackbar('Success', 'Experiment session created');
  }

  /// Start interval-based recording
  Future<void> startIntervalRecording() async {
    if (isRecording.value) {
      Get.snackbar('Warning', 'Recording already in progress');
      return;
    }

    if (currentSession.value == null) {
      Get.snackbar('Error', 'Create a session first');
      return;
    }

    try {
      isRecording.value = true;
      _recordCount = 0;
      recordingProgress.value = 0;
      recordingMessage.value = 'Recording started...';

      // Initialize GPS if not already done
      if (!gpsController.isGPSInitialized.value) {
        recordingMessage.value = 'Initializing GPS...';
        await gpsController.initializeGPS();
      }

      final interval = Duration(seconds: currentSession.value!.intervalSeconds);

      // Start interval timer
      _recordingTimer = Timer.periodic(interval, (timer) async {
        await _recordSinglePoint();
      });

      // Also record immediately
      await _recordSinglePoint();

      print('$_logTag Interval recording started (${currentSession.value!.intervalSeconds}s)');
      Get.snackbar('Recording', 'Recording started every ${currentSession.value!.intervalSeconds} seconds');

    } catch (e) {
      isRecording.value = false;
      Get.snackbar('Error', 'Failed to start recording: $e');
      print('$_logTag Error starting recording: $e');
    }
  }

  /// Record single location point from both providers
  Future<void> _recordSinglePoint() async {
    try {
      _recordCount++;
      recordingMessage.value = 'Recording point $_recordCount...';
      recordingProgress.value = _recordCount;

      // Get GPS location
      try {
        await gpsController.getCurrentLocation();
        if (gpsController.currentPosition.value != null) {
          final gpsEntry = LocationHistoryEntry.fromPosition(
            gpsController.currentPosition.value!,
            locationType: 'gps',
            address: gpsController.currentAddress.value,
          );
          
          currentSession.value!.gpsData.add(gpsEntry);
          print('$_logTag GPS recorded: ${gpsEntry.latitude}, ${gpsEntry.longitude}');
        }
      } catch (e) {
        print('$_logTag GPS recording failed: $e');
      }

      // Get Network location
      try {
        await networkController.getCurrentNetworkLocation();
        
        final netLocValue = networkController.networkLocation;
        if (netLocValue != null) {
          final double latitude = (netLocValue['latitude'] as double?) ?? 0.0;
          final double longitude = (netLocValue['longitude'] as double?) ?? 0.0;
          final double accuracy = (netLocValue['accuracy'] as double?) ?? 0.0;
          final String address = (netLocValue['address'] as String?) ?? 
                                 (netLocValue['city'] as String?) ?? 
                                 'Unknown';

          final networkEntry = LocationHistoryEntry(
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            timestamp: DateTime.now(),
            address: address,
            locationType: 'network',
          );
          
          currentSession.value!.networkData.add(networkEntry);
          print('$_logTag Network recorded: $latitude, $longitude');
        }
      } catch (e) {
        print('$_logTag Network recording failed: $e');
      }

      // Update UI
      currentSession.refresh();

    } catch (e) {
      print('$_logTag Error in _recordSinglePoint: $e');
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    isRecording.value = false;

    if (currentSession.value != null) {
      currentSession.value!.metadata['completedAt'] = DateTime.now().toIso8601String();
      currentSession.value!.metadata['totalRecords'] = currentSession.value!.totalRecords;
    }

    recordingMessage.value = 'Recording stopped. Saved to session.';
    print('$_logTag Recording stopped');
    Get.snackbar('Success', 'Recording stopped');
  }

  /// Save current session permanently
  Future<void> saveCurrentSession() async {
    if (currentSession.value == null) {
      Get.snackbar('Error', 'No session to save');
      return;
    }

    try {
      // Update completed time
      currentSession.value = ExperimentSession(
        id: currentSession.value!.id,
        name: currentSession.value!.name,
        createdAt: currentSession.value!.createdAt,
        completedAt: DateTime.now(),
        intervalSeconds: currentSession.value!.intervalSeconds,
        gpsData: currentSession.value!.gpsData,
        networkData: currentSession.value!.networkData,
        metadata: currentSession.value!.metadata,
      );

      // Check if session already exists
      final existingIndex = sessions.indexWhere((s) => s.id == currentSession.value!.id);
      
      if (existingIndex >= 0) {
        sessions[existingIndex] = currentSession.value!;
      } else {
        sessions.add(currentSession.value!);
      }

      sessions.refresh();

      recordingMessage.value = 'Session saved successfully!';
      print('$_logTag Session saved: ${currentSession.value!.name}');
      Get.snackbar('Success', 'Session saved successfully');

    } catch (e) {
      Get.snackbar('Error', 'Failed to save session: $e');
      print('$_logTag Error saving session: $e');
    }
  }

  /// Load a saved session
  Future<void> loadSession(ExperimentSession session) async {
    currentSession.value = session;
    recordingMessage.value = 'Session loaded: ${session.name}';
    recordingProgress.value = session.totalRecords;
    print('$_logTag Session loaded: ${session.name}');
    Get.snackbar('Success', 'Session loaded');
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      sessions.removeWhere((s) => s.id == sessionId);
      
      sessions.refresh();

      if (currentSession.value?.id == sessionId) {
        currentSession.value = null;
      }

      print('$_logTag Session deleted: $sessionId');
      Get.snackbar('Success', 'Session deleted');

    } catch (e) {
      Get.snackbar('Error', 'Failed to delete session: $e');
      print('$_logTag Error deleting session: $e');
    }
  }

  /// Export session data to CSV
  String exportToCSV() {
    if (currentSession.value == null) return '';

    final session = currentSession.value!;
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Experiment Session Export');
    buffer.writeln('Name,${session.name}');
    buffer.writeln('Created,${session.createdAt}');
    buffer.writeln('Interval,${session.intervalSeconds}s');
    buffer.writeln('');

    // GPS Data
    buffer.writeln('GPS Data');
    buffer.writeln('Timestamp,Latitude,Longitude,Accuracy,Speed,Altitude');
    for (var entry in session.gpsData) {
      buffer.writeln('${entry.timestamp},${entry.latitude},${entry.longitude},${entry.accuracy},${entry.speed ?? 0},${entry.altitude ?? 0}');
    }
    buffer.writeln('');

    // Network Data
    buffer.writeln('Network Data');
    buffer.writeln('Timestamp,Latitude,Longitude,Accuracy,Speed,Altitude');
    for (var entry in session.networkData) {
      buffer.writeln('${entry.timestamp},${entry.latitude},${entry.longitude},${entry.accuracy},${entry.speed ?? 0},${entry.altitude ?? 0}');
    }
    buffer.writeln('');

    // Statistics
    buffer.writeln('Statistics');
    buffer.writeln('GPS Average Accuracy,${session.gpsAverageAccuracy.toStringAsFixed(2)}m');
    buffer.writeln('Network Average Accuracy,${session.networkAverageAccuracy.toStringAsFixed(2)}m');
    buffer.writeln('Accuracy Difference,${session.accuracyDifference.toStringAsFixed(2)}m');

    return buffer.toString();
  }

  @override
  void onClose() {
    _recordingTimer?.cancel();
    print('$_logTag Disposed');
    super.onClose();
  }
}
