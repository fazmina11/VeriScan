import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../core/theme_controller.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';

class ControlCenterScreen extends ConsumerStatefulWidget {
  const ControlCenterScreen({super.key});

  @override
  ConsumerState<ControlCenterScreen> createState() =>
      _ControlCenterScreenState();
}

class _ControlCenterScreenState extends ConsumerState<ControlCenterScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _ringController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  final TextEditingController _searchController = TextEditingController();

  // ── User data state ──────────────────────────────────────────────────────
  String _fullName = '';
  String _role = '';
  String _labName = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      const storage = FlutterSecureStorage();
      final userJson = await storage.read(key: 'user_data');
      if (userJson != null) {
        final user = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          _fullName = user['full_name'] ?? '';
          _role = user['role'] ?? '';
          _labName = user['lab_name'] ?? '';
          _isLoadingUser = false;
        });
      } else {
        setState(() => _isLoadingUser = false);
      }
    } catch (e) {
      setState(() => _isLoadingUser = false);
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _floatController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Role display helpers ─────────────────────────────────────────────────

  String _getRoleDisplay(String role) {
    const roleMap = {
      'lab_technician': '🔬 Lab Technician',
      'pathologist': '👨‍⚕️ Pathologist',
      'pharmacist': '💊 Pharmacist',
      'lab_manager': '🏥 Lab Manager',
      'clinical_researcher': '🩺 Clinical Researcher',
      'quality_control_officer': '📋 QC Officer',
    };
    return roleMap[role] ?? role;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _showLogoutDialog() async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: VeriScanTheme.cyan.withAlpha(60),
          ),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'auth_token');
              await storage.delete(key: 'user_data');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(
                color: Color(0xFFFF2E2E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // ── Top Bar ──
              _buildTopBar(),
              const SizedBox(height: 16),
              // ── User Greeting Card ──
              _buildUserGreetingCard(),
              const SizedBox(height: 24),
              // ── Device Visualization ──
              Expanded(child: _buildDeviceVisualization()),
              // ── Search ──
              _buildSearchField(),
              const SizedBox(height: 20),
              // ── Scan Button ──
              GlowingButton(
                label: 'START NEW SCAN',
                icon: Icons.radar_rounded,
                onPressed: () => Navigator.pushNamed(context, '/scanning'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VeriScan',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                shadows: NeonStyles.textGlow(VeriScanTheme.cyan),
              ),
            ),
            const SizedBox(height: 2),
            Text('Control Center',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Row(
          children: [
            // Battery
            GlassCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 12,
              child: Row(
                children: [
                  const Icon(Icons.battery_5_bar_rounded,
                      color: VeriScanTheme.green, size: 18),
                  const SizedBox(width: 4),
                  Text('87%',
                      style: const TextStyle(
                          color: VeriScanTheme.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Scans
            GlassCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 12,
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded,
                      color: VeriScanTheme.cyan, size: 18),
                  const SizedBox(width: 4),
                  Text('142',
                      style: const TextStyle(
                          color: VeriScanTheme.cyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Theme toggle
            GlassCard(
              padding: const EdgeInsets.all(4),
              borderRadius: 12,
              child: IconButton(
                icon: Icon(
                  ref.watch(themeModeProvider) == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: VeriScanTheme.cyan,
                  size: 20,
                ),
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggle(),
                tooltip: 'Toggle theme',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ),
            const SizedBox(width: 8),
            // Logout button
            GlassCard(
              padding: const EdgeInsets.all(4),
              borderRadius: 12,
              child: IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Color(0xFF00F0FF),
                  size: 20,
                ),
                onPressed: _showLogoutDialog,
                tooltip: 'Logout',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserGreetingCard() {
    if (_isLoadingUser) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D26),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: const Color(0xFF00F0FF), width: 2),
            left: BorderSide(color: Colors.white.withAlpha(10)),
            right: BorderSide(color: Colors.white.withAlpha(10)),
            bottom: BorderSide(color: Colors.white.withAlpha(10)),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Color(0xFF00F0FF),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D26),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: const BorderSide(color: Color(0xFF00F0FF), width: 2),
          left: BorderSide(color: Colors.white.withAlpha(15)),
          right: BorderSide(color: Colors.white.withAlpha(15)),
          bottom: BorderSide(color: Colors.white.withAlpha(15)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00F0FF).withAlpha(20),
              border: Border.all(
                color: const Color(0xFF00F0FF).withAlpha(100),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF00F0FF),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting + name
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_getGreeting()} ',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: _fullName.isNotEmpty ? _fullName : 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Role badge
                if (_role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withAlpha(80),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getRoleDisplay(_role),
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // Lab name
                if (_labName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _labName,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceVisualization() {
    return Center(
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _ringController.value * 2 * pi,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          VeriScanTheme.cyan.withAlpha(0),
                          VeriScanTheme.cyan.withAlpha(80),
                          VeriScanTheme.purple.withAlpha(80),
                          VeriScanTheme.purple.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Device body
            Container(
              width: 140,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D26),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: VeriScanTheme.cyan.withAlpha(60),
                  width: 1.5,
                ),
                boxShadow:
                    NeonStyles.neonShadow(VeriScanTheme.cyan, blur: 30, spread: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VeriScanTheme.cyan.withAlpha(30),
                      border: Border.all(
                          color: VeriScanTheme.cyan.withAlpha(100)),
                    ),
                    child: const Icon(Icons.sensors_rounded,
                        color: VeriScanTheme.cyan, size: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'VeriScan',
                    style: TextStyle(
                      color: VeriScanTheme.cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIR Sensor',
                    style: TextStyle(
                      color: VeriScanTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: VeriScanTheme.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CONNECTED',
                      style: TextStyle(
                        color: VeriScanTheme.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Select Medicine',
          hintStyle: TextStyle(color: VeriScanTheme.textMuted),
          prefixIcon: const Icon(Icons.search_rounded,
              color: VeriScanTheme.cyan, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: VeriScanTheme.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(10)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) {
          setState(() => _currentNavIndex = i);
          if (i == 2) {
            Navigator.pushNamed(context, '/community-map');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            activeIcon: _buildActiveNavIcon(Icons.home_rounded),
            label: 'Hub',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            activeIcon: _buildActiveNavIcon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_rounded),
            activeIcon: _buildActiveNavIcon(Icons.map_rounded),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            activeIcon: _buildActiveNavIcon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveNavIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: VeriScanTheme.cyan.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: VeriScanTheme.cyan.withAlpha(60),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(icon, color: VeriScanTheme.cyan),
    );
  }
}
