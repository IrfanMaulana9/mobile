import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message received: ${message.messageId}');
  print('Background message data: ${message.data}');
  print('Background message notification: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static const platform = MethodChannel('com.mobile.modul6/notification');
  
  final StreamController<NotificationItem> _notificationStreamController = 
      StreamController<NotificationItem>.broadcast();
  
  Stream<NotificationItem> get notificationStream => _notificationStreamController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // In-memory cache for persisted notifications (so controllers/pages can read synchronously)
  final List<NotificationItem> _cachedNotifications = <NotificationItem>[];
  bool _cacheLoaded = false;

  static const String _highImportanceChannelId = 'high_importance_channel';
  static const String _highImportanceChannelName = 'High Importance Notifications';
  static const String _highImportanceChannelDescription = 'This channel is used for important notifications.';
  
  static const String _progressChannelId = 'progress_channel';
  static const String _progressChannelName = 'Progress Notifications';
  static const String _progressChannelDescription = 'This channel is used for progress notifications.';

  static const String _customSoundChannelId = 'custom_sound_channel';
  static const String _customSoundChannelName = 'Custom Sound Notifications';
  static const String _customSoundChannelDescription = 'Notifications with custom sound.';

  Future<void> initialize() async {
    try {
      print('Starting FCM initialization...');
      
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      await _initializeLocalNotifications();
      await _initializeNativeChannelHandlers();
      await _loadNotificationsCache();

      try {
        _fcmToken = await _firebaseMessaging.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('FCM token request timed out');
            return null;
          },
        );
        print('FCM Token: $_fcmToken');
      } catch (e) {
        print('Error getting FCM token: $e');
        print('Continuing without FCM token - check Firebase Console setup');
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

      await _checkInitialNotification();
      
      print('FCM initialization completed successfully');
    } catch (e) {
      print('Error initializing FCM: $e');
      print('App will continue without push notifications');
    }
  }

  Future<void> _loadNotificationsCache() async {
    if (_cacheLoaded) return;
    final loaded = await getSavedNotificationsAsync();
    _cachedNotifications
      ..clear()
      ..addAll(loaded);
    _cacheLoaded = true;
    print('Loaded ${_cachedNotifications.length} saved notifications from storage');
  }

  Future<void> _initializeNativeChannelHandlers() async {
    try {
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onNotificationTapped') {
          try {
            final args = call.arguments;
            if (args is Map) {
              final data = Map<String, dynamic>.from(args);
              print('Native notification tapped: $data');
              _navigateToPage(data);
            } else {
              print('Native notification tapped with non-map args: $args');
            }
          } catch (e) {
            print('Error handling native notification tap: $e');
          }
        }
      });
    } catch (e) {
      print('Error initializing native channel handlers: $e');
    }
  }

  Future<void> _checkInitialNotification() async {
    try {
      // Check dari FCM
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from terminated state via FCM notification');
        print('Initial message data: ${initialMessage.data}');
        _handleNotificationOpenedApp(initialMessage);
        return;
      }

      // Check dari Native Android via MethodChannel
      final Map<dynamic, dynamic>? notificationData = 
          await platform.invokeMethod('getInitialNotification');
      
      if (notificationData != null && notificationData.isNotEmpty) {
        print('App opened from terminated state via native notification');
        print('Notification data from native: $notificationData');
        
        // Convert to Map<String, dynamic>
        final data = Map<String, dynamic>.from(notificationData);
        _navigateToPage(data);
      }
    } catch (e) {
      print('Error checking initial notification: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      _highImportanceChannelId,
      _highImportanceChannelName,
      description: _highImportanceChannelDescription,
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);

    const AndroidNotificationChannel customSoundChannel = AndroidNotificationChannel(
      _customSoundChannelId,
      _customSoundChannelName,
      description: _customSoundChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('ketawa'),
      enableVibration: true,
      enableLights: true,
      showBadge: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel(_customSoundChannelId);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(customSoundChannel);

    const AndroidNotificationChannel progressChannel = AndroidNotificationChannel(
      _progressChannelId,
      _progressChannelName,
      description: _progressChannelDescription,
      importance: Importance.low,
      showBadge: false,
      playSound: false,
      enableVibration: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(progressChannel);

    print('All notification channels created successfully');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.messageId}');
    print('Payload data: ${message.data}');
    print('Notification: ${message.notification?.title}');

    final notificationItem = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: message.data,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notificationStreamController.add(notificationItem);
    await saveNotification(notificationItem);

    await _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _customSoundChannelId,
      _customSoundChannelName,
      channelDescription: _customSoundChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('ketawa'),
      enableVibration: true,
      enableLights: true,
      color: Color.fromARGB(255, 255, 0, 0),
      ledColor: Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'New notification',
      visibility: NotificationVisibility.public,
      channelShowBadge: true,
      autoCancel: true,
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'ketawa.mp3',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
    
    print('Local notification shown with ketawa.mp3 sound');
  }

  void _handleNotificationOpenedApp(RemoteMessage message) {
    print('Notification opened: ${message.messageId}');
    print('Notification data: ${message.data}');

    final notificationItem = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: message.data,
      timestamp: DateTime.now(),
      isRead: false,
    );
    
    saveNotification(notificationItem);
    _notificationStreamController.add(notificationItem);

    _navigateToPage(message.data);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped');
    print('Payload: ${response.payload}');

    if (response.payload != null) {
      try {
        final decoded = jsonDecode(response.payload!);
        if (decoded is Map) {
          _navigateToPage(Map<String, dynamic>.from(decoded));
        } else {
          print('Notification payload is not a JSON map');
        }
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  void _navigateToPage(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final route = data['route'] ?? '';

    print('Navigating to: type=$type, route=$route');

    Future.delayed(const Duration(milliseconds: 800), () {
      if (route.isNotEmpty) {
        print('Navigating to route: $route');
        Get.toNamed(route);
      } else {
        switch (type) {
          case 'promo':
            print('Navigating to promo page');
            Get.toNamed('/promo');
            break;
          case 'booking':
          case 'order':
            print('Navigating to booking history');
            Get.toNamed('/booking-history');
            break;
          case 'notification':
            print('Navigating to notifications page');
            Get.toNamed('/notifications');
            break;
          default:
            print('Navigating to notifications page (default)');
            Get.toNamed('/notifications');
        }
      }
    });
  }

  // Save notifications to local storage
  List<NotificationItem> getSavedNotifications() {
    return List<NotificationItem>.from(_cachedNotifications);
  }

  /// Async version used internally to correctly load persisted notifications
  Future<List<NotificationItem>> getSavedNotificationsAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('notifications');
      if (jsonString == null || jsonString.isEmpty) return [];

      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return [];

      final list = decoded
          .whereType<Map>()
          .map((m) => NotificationItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      return list;
    } catch (e) {
      print('Error loading saved notifications: $e');
      return [];
    }
  }

  Future<void> saveNotification(NotificationItem notification) async {
    final prefs = await SharedPreferences.getInstance();
    // Update cache first
    _cachedNotifications.removeWhere((n) => n.id == notification.id);
    _cachedNotifications.insert(0, notification);
    
    if (_cachedNotifications.length > 50) {
      _cachedNotifications.removeRange(50, _cachedNotifications.length);
    }

    final jsonList = _cachedNotifications.map((n) => n.toJson()).toList();
    await prefs.setString('notifications', jsonEncode(jsonList));
  }

  Future<void> updateNotification(NotificationItem notification) async {
    final prefs = await SharedPreferences.getInstance();
    final index = _cachedNotifications.indexWhere((n) => n.id == notification.id);
    
    if (index != -1) {
      _cachedNotifications[index] = notification;
      final jsonList = _cachedNotifications.map((n) => n.toJson()).toList();
      await prefs.setString('notifications', jsonEncode(jsonList));
    }
  }

  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedNotifications.removeWhere((n) => n.id == id);
    
    final jsonList = _cachedNotifications.map((n) => n.toJson()).toList();
    await prefs.setString('notifications', jsonEncode(jsonList));
  }

  Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedNotifications.clear();
    await prefs.remove('notifications');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool useCustomSound = true,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      useCustomSound ? _customSoundChannelId : _highImportanceChannelId,
      useCustomSound ? _customSoundChannelName : _highImportanceChannelName,
      channelDescription: useCustomSound ? _customSoundChannelDescription : _highImportanceChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: useCustomSound ? const RawResourceAndroidNotificationSound('ketawa') : null,
      enableVibration: true,
      enableLights: true,
      color: const Color.fromARGB(255, 255, 0, 0),
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'New notification',
      visibility: NotificationVisibility.public,
      channelShowBadge: true,
      autoCancel: true,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'ketawa.mp3',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    Map<String, dynamic> dataMap = {'payload': payload ?? ''};
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          dataMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // ignore payload parsing errors
      }
    }

    final notificationItem = NotificationItem(
      id: id.toString(),
      title: title,
      body: body,
      data: dataMap,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notificationStreamController.add(notificationItem);
    await saveNotification(notificationItem);
    print('Notification shown with ID: $id, Custom Sound: $useCustomSound, Sound File: ketawa.mp3');
  }

  Future<void> showProgressNotification({
    required String title,
    required int progress,
    required int maxProgress,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _progressChannelId,
      _progressChannelName,
      channelDescription: _progressChannelDescription,
      importance: Importance.low,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      playSound: false,
      enableVibration: false,
      ongoing: progress < maxProgress,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      999,
      title,
      progress < maxProgress 
          ? '$progress% complete' 
          : 'Download complete!',
      notificationDetails,
    );
  }

  void dispose() {
    _notificationStreamController.close();
  }
}
