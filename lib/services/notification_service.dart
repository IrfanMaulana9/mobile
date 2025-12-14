import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[v0] Background message received: ${message.messageId}');
  print('[v0] Background message data: ${message.data}');
  print('[v0] Background message notification: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  final StreamController<NotificationItem> _notificationStreamController = 
      StreamController<NotificationItem>.broadcast();
  
  Stream<NotificationItem> get notificationStream => _notificationStreamController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

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
      print('[v0] Starting FCM initialization...');
      
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('[v0] Notification permission status: ${settings.authorizationStatus}');

      await _initializeLocalNotifications();

      try {
        _fcmToken = await _firebaseMessaging.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('[v0] FCM token request timed out');
            return null;
          },
        );
        print('[v0] FCM Token: $_fcmToken');
      } catch (e) {
        print('[v0] Error getting FCM token: $e');
        print('[v0] Continuing without FCM token - check Firebase Console setup');
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('[v0] FCM Token refreshed: $newToken');
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('[v0] App opened from terminated state via notification');
        _handleNotificationOpenedApp(initialMessage);
      }
      
      print('[v0] FCM initialization completed successfully');
    } catch (e) {
      print('[v0] Error initializing FCM: $e');
      print('[v0] App will continue without push notifications');
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
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
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
      sound: RawResourceAndroidNotificationSound('tungsahur'), // Custom sound from raw folder
      enableVibration: true,
      showBadge: true,
    );

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

    print('[v0] All notification channels created successfully');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('[v0] Foreground message received: ${message.messageId}');
    print('[v0] Payload data: ${message.data}');
    print('[v0] Notification: ${message.notification?.title}');

    final notificationItem = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: message.data,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notificationStreamController.add(notificationItem);

    await _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _customSoundChannelId,
      _customSoundChannelName,
      channelDescription: _customSoundChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('tungsahur'),
      enableVibration: true,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'tungsahur.mp3',
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
  }

  void _handleNotificationOpenedApp(RemoteMessage message) {
    print('[v0] Notification opened: ${message.messageId}');
    print('[v0] Notification data: ${message.data}');

    _navigateToPage(message.data);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('[v0] Local notification tapped');
    print('[v0] Payload: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _navigateToPage(data);
      } catch (e) {
        print('[v0] Error parsing notification payload: $e');
      }
    }
  }

  void _navigateToPage(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final route = data['route'] ?? '';

    print('[v0] Navigating to: type=$type, route=$route');

    if (route.isNotEmpty) {
      Get.toNamed(route);
    } else {
      switch (type) {
        case 'promo':
          Get.toNamed('/promo');
          break;
        case 'booking':
        case 'order':
          Get.toNamed('/booking-history');
          break;
        case 'notification':
          Get.toNamed('/notifications');
          break;
        default:
          Get.toNamed('/notifications');
      }
    }
  }

  // Save notifications to local storage
  List<NotificationItem> getSavedNotifications() {
    return [];
  }

  Future<void> saveNotification(NotificationItem notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = getSavedNotifications();
    notifications.insert(0, notification);
    
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }

    final jsonList = notifications.map((n) => n.toJson()).toList();
    await prefs.setString('notifications', jsonEncode(jsonList));
  }

  Future<void> updateNotification(NotificationItem notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = getSavedNotifications();
    final index = notifications.indexWhere((n) => n.id == notification.id);
    
    if (index != -1) {
      notifications[index] = notification;
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString('notifications', jsonEncode(jsonList));
    }
  }

  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = getSavedNotifications();
    notifications.removeWhere((n) => n.id == id);
    
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await prefs.setString('notifications', jsonEncode(jsonList));
  }

  Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
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
      priority: Priority.high,
      playSound: true,
      sound: useCustomSound ? const RawResourceAndroidNotificationSound('tungsahur') : null,
      enableVibration: true,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'tungsahur.mp3',
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

    final notificationItem = NotificationItem(
      id: id.toString(),
      title: title,
      body: body,
      data: {'payload': payload ?? ''},
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notificationStreamController.add(notificationItem);
    print('[v0] Notification shown with ID: $id, Custom Sound: $useCustomSound');
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
      999, // Fixed ID for progress notifications so they update the same notification
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
