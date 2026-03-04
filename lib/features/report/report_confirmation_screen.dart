import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/glowing_button.dart';

class ReportConfirmationScreen extends StatefulWidget {
  const ReportConfirmationScreen({super.key});

  @override
  State<ReportConfirmationScreen> createState() =>
      _ReportConfirmationScreenState();
}

class _ReportConfirmationScreenState extends State<ReportConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              VeriScanTheme.red.withAlpha(30),
              VeriScanTheme.purple.withAlpha(15),
              VeriScanTheme.background,
            ],
            radius: 0.8,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // ── Icon ──
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          VeriScanTheme.red,
                          VeriScanTheme.purple,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VeriScanTheme.red.withAlpha(80),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: VeriScanTheme.purple.withAlpha(60),
                          blurRadius: 40,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Report Submitted to\nGlobal Fraud Map',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thank you for protecting\nyour community.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: VeriScanTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Report ID
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(15)),
                    ),
                    child: Text(
                      'Report ID: FR-2026-0218-7A3F',
                      style: TextStyle(
                        color: VeriScanTheme.textMuted,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  GlowingButton(
                    label: 'VIEW COMMUNITY MAP',
                    icon: Icons.map_rounded,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/community-map',
                      (_) => false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlowingButton(
                    label: 'BACK TO HOME',
                    icon: Icons.home_rounded,
                    type: GlowButtonType.primary,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/hub',
                      (_) => false,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
