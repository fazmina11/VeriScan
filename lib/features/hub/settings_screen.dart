import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: VeriScanTheme.background,
      appBar: AppBar(
        backgroundColor: VeriScanTheme.background,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildSection(
            title: 'Account',
            tiles: [
              _buildTile(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                iconColor: VeriScanTheme.cyan,
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                iconColor: VeriScanTheme.cyan,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'App',
            tiles: [
              _buildTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                iconColor: VeriScanTheme.purple,
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.info_outline_rounded,
                label: 'About VeriScan',
                iconColor: VeriScanTheme.purple,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Session',
            tiles: [
              _buildLogoutTile(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> tiles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF555566),
        size: 20,
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'LOGOUT',
                  style: TextStyle(color: Color(0xFFFF2E2E), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          const storage = FlutterSecureStorage();
          await storage.delete(key: 'auth_token');
          await storage.delete(key: 'user_data');
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        }
      },
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFF2E2E).withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.logout_rounded,
            color: Color(0xFFFF2E2E), size: 20),
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: Color(0xFFFF2E2E),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
