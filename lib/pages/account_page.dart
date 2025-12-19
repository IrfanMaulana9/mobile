import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/storage_controller.dart';
import 'payment_history_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final authController = Get.find<AuthController>();
  final storageController = Get.find<StorageController>();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: cs.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.onPrimary.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: cs.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(() => Text(
                        authController.currentUserEmail.isNotEmpty
                            ? authController.currentUserEmail
                            : 'User Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.onPrimary,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Information Card
                  _buildProfileCard(context, cs),
                  const SizedBox(height: 24),

                  // Account Status Card
                  _buildStatusCard(context, cs),
                  const SizedBox(height: 24),

                  // Settings Section
                  Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Settings Items
                  _buildSettingsItem(
                    context,
                    cs,
                    icon: Icons.payment,
                    title: 'Riwayat Pembayaran',
                    subtitle: 'Lihat semua transaksi pembayaran',
                    onTap: () {
                      Get.toNamed('/payment-history');
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    cs,
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi',
                    subtitle: 'Kelola notifikasi aplikasi',
                    onTap: () {
                      Get.snackbar(
                        'Notifikasi',
                        'Fitur akan segera tersedia',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    cs,
                    icon: Icons.help_outline,
                    title: 'Bantuan & Dukungan',
                    subtitle: 'Hubungi tim dukungan kami',
                    onTap: () {
                      Get.snackbar(
                        'Bantuan',
                        'Fitur akan segera tersedia',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Danger Zone
                  Text(
                    'Aksi Berbahaya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Profil',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              label: 'Email',
              value: Obx(() => Text(authController.currentUserEmail)),
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              label: 'ID Pengguna',
              value: Obx(() => Text(authController.currentUserId)),
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              label: 'Status',
              value: const Text('Aktif'),
              icon: Icons.check_circle_outlined,
              valueColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, ColorScheme cs) {
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  color: cs.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        authController.isAuthenticated.value
                            ? 'Akun Terhubung'
                            : 'Akun Offline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      )),
                      Obx(() => Text(
                        authController.isAuthenticated.value
                            ? 'Data Anda tersinkronisasi dengan cloud'
                            : 'Mode offline - data tersimpan lokal',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.primary.withValues(alpha: 0.7),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: cs.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required Widget value,
    required IconData icon,
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? cs.onSurface,
                ),
                child: value,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Data yang belum tersinkronisasi akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
