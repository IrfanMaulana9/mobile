import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert'; // Added jsonEncode import for payload encoding
import '../services/notification_service.dart';
import '../controllers/notification_controller.dart';

class TestNotificationsPage extends StatefulWidget {
  static const String routeName = '/test-notifications';
  
  const TestNotificationsPage({super.key});

  @override
  State<TestNotificationsPage> createState() => _TestNotificationsPageState();
}

class _TestNotificationsPageState extends State<TestNotificationsPage> {
  final notificationService = NotificationService();
  final notificationController = Get.find<NotificationController>();
  bool _isPlayingSound = false;
  bool _isShowingNotification = false;
  bool _isShowingProgress = false;
  bool _isSendingPromo = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Test Notifications',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: cs.surface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Prominent Promo Notification button for Eksperimen 2 & 3
          _buildTestCard(
            context: context,
            icon: Icons.local_offer,
            iconColor: const Color(0xFFFF6B6B),
            iconBgColor: const Color(0xFFFF6B6B).withOpacity(0.1),
            title: '🎉 Notifikasi Promo (EKSPERIMEN 2 & 3)',
            subtitle: 'Kirim notifikasi yang navigasi ke halaman promo. Untuk testing dari Firebase Console, baca FIREBASE_CONSOLE_GUIDE.md',
            buttonText: 'Kirim',
            buttonColor: const Color(0xFFFF6B6B),
            isLoading: _isSendingPromo,
            onPressed: () async {
              setState(() => _isSendingPromo = true);
              
              await notificationService.showNotification(
                title: '🎉 Promo Spesial!',
                body: 'Diskon 50% untuk layanan pembersihan! Tap untuk lihat detail promo.',
                payload: jsonEncode({
                  'type': 'promo',
                  'route': '/promo',
                }),
                useCustomSound: true,
              );
              
              setState(() => _isSendingPromo = false);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Notifikasi promo terkirim! Tap notifikasi untuk navigasi ke halaman promo.'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Color(0xFFFF6B6B),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Custom Audio Notification
          _buildTestCard(
            context: context,
            icon: Icons.music_note,
            iconColor: const Color(0xFFE91E63),
            iconBgColor: const Color(0xFFE91E63).withOpacity(0.1),
            title: 'Custom Audio Notification',
            subtitle: 'Plays a custom sound',
            buttonText: 'Play',
            buttonColor: const Color(0xFF2196F3),
            isLoading: _isPlayingSound,
            onPressed: () async {
              setState(() => _isPlayingSound = true);
              
              await notificationService.showNotification(
                title: 'Custom Sound Test',
                body: 'Playing custom audio notification with ketawa.mp3',
                payload: jsonEncode({'type': 'notification'}),
              );
              
              await Future.delayed(const Duration(seconds: 2));
              
              setState(() => _isPlayingSound = false);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Custom audio notification sent!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Instant Notification
          _buildTestCard(
            context: context,
            icon: Icons.notifications_active,
            iconColor: const Color(0xFFFF9800),
            iconBgColor: const Color(0xFFFF9800).withOpacity(0.1),
            title: 'Instant Notification',
            subtitle: 'Test instant notification',
            buttonText: 'Show',
            buttonColor: const Color(0xFF2196F3),
            isLoading: _isShowingNotification,
            onPressed: () async {
              setState(() => _isShowingNotification = true);
              
              await notificationService.showNotification(
                title: 'Instant Test',
                body: 'This is an instant notification test. Tap to see details!',
                payload: jsonEncode({'type': 'notification'}),
              );
              
              await Future.delayed(const Duration(milliseconds: 500));
              
              setState(() => _isShowingNotification = false);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Instant notification sent!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Progress Notification
          _buildTestCard(
            context: context,
            icon: Icons.download,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: const Color(0xFF4CAF50).withOpacity(0.1),
            title: 'Progress Notification',
            subtitle: 'Simulates a download progress',
            buttonText: 'Start',
            buttonColor: const Color(0xFF2196F3),
            isLoading: _isShowingProgress,
            onPressed: () async {
              setState(() => _isShowingProgress = true);
              
              for (int i = 0; i <= 100; i += 20) {
                await notificationService.showProgressNotification(
                  title: 'Downloading File',
                  progress: i,
                  maxProgress: 100,
                );
                
                if (i < 100) {
                  await Future.delayed(const Duration(milliseconds: 800));
                }
              }
              
              await notificationService.showNotification(
                title: 'Download Complete',
                body: 'File has been downloaded successfully!',
                payload: 'download_complete',
              );
              
              setState(() => _isShowingProgress = false);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress notification completed!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Additional test options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuTile(
                  context: context,
                  icon: Icons.history,
                  iconColor: const Color(0xFFFF9800),
                  iconBgColor: const Color(0xFFFF9800).withOpacity(0.1),
                  title: 'Riwayat Notifikasi',
                  subtitle: 'Lihat notifikasi masuk',
                  onTap: () {
                    Get.toNamed('/notifications');
                  },
                ),
                
                const SizedBox(height: 12),
                
                _buildMenuTile(
                  context: context,
                  icon: Icons.notification_add,
                  iconColor: const Color(0xFF9C27B0),
                  iconBgColor: const Color(0xFF9C27B0).withOpacity(0.1),
                  title: 'Test Notifikasi',
                  subtitle: 'Coba berbagai jenis notifikasi',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Additional Tests'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: const Text('Scheduled Notification'),
                              subtitle: const Text('Test delayed notification'),
                              onTap: () async {
                                Navigator.pop(context);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Scheduled for 5 seconds...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                
                                await Future.delayed(const Duration(seconds: 5));
                                
                                await notificationService.showNotification(
                                  title: 'Scheduled Test',
                                  body: 'This notification was scheduled 5 seconds ago!',
                                  payload: 'scheduled_test',
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.priority_high),
                              title: const Text('High Priority'),
                              subtitle: const Text('Test high priority notification'),
                              onTap: () async {
                                Navigator.pop(context);
                                
                                await notificationService.showNotification(
                                  title: 'High Priority Alert!',
                                  body: 'This is a high priority notification',
                                  payload: 'high_priority_test',
                                );
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('High priority notification sent!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
