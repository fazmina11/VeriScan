import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../core/theme_controller.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';

class ControlCenterScreen extends ConsumerStatefulWidget {
  const ControlCenterScreen({super.key});

  @override
  ConsumerState<ControlCenterScreen> createState() => _ControlCenterScreenState();
}

class _ControlCenterScreenState extends ConsumerState<ControlCenterScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _ringController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  final TextEditingController _searchController = TextEditingController();

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
  }

  @override
  void dispose() {
    _ringController.dispose();
    _floatController.dispose();
    _searchController.dispose();
    super.dispose();
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
              const SizedBox(height: 32),
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
            Text('Control Center', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Row(
          children: [
            // Battery
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 12,
              child: Row(
                children: [
                  const Icon(Icons.battery_5_bar_rounded,
                      color: VeriScanTheme.green, size: 18),
                  const SizedBox(width: 4),
                  Text('87%',
                      style: TextStyle(
                          color: VeriScanTheme.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Scans
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 12,
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded,
                      color: VeriScanTheme.cyan, size: 18),
                  const SizedBox(width: 4),
                  Text('142',
                      style: TextStyle(
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
          ],
        ),
      ],
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
                boxShadow: NeonStyles.neonShadow(VeriScanTheme.cyan, blur: 30, spread: 2),
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
                      border: Border.all(color: VeriScanTheme.cyan.withAlpha(100)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            icon: Icon(Icons.home_rounded),
            activeIcon: _buildActiveNavIcon(Icons.home_rounded),
            label: 'Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: _buildActiveNavIcon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            activeIcon: _buildActiveNavIcon(Icons.map_rounded),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
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
