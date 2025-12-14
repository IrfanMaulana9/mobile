import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _notificationService = NotificationService();
  
  // Observable list of notifications
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    isLoading.value = true;
    try {
      await _notificationService.initialize();
      _loadNotifications();
      
      // Listen for new notifications
      _notificationService.notificationStream.listen((notificationItem) {
        addNotification(notificationItem);
      });
    } catch (e) {
      print('[v0] Error initializing notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _loadNotifications() {
    // Load saved notifications from storage
    notifications.value = _notificationService.getSavedNotifications();
  }

  void addNotification(NotificationItem notification) {
    notifications.insert(0, notification);
    _notificationService.saveNotification(notification);
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _notificationService.updateNotification(notifications[index]);
    }
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    _notificationService.deleteNotification(id);
  }

  void clearAll() {
    notifications.clear();
    _notificationService.clearAllNotifications();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}
  