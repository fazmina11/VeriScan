import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glowing_button.dart';

class DangerResultScreen extends StatefulWidget {
  const DangerResultScreen({super.key});

  @override
  State<DangerResultScreen> createState() => _DangerResultScreenState();
}

class _DangerResultScreenState extends State<DangerResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: VeriScanTheme.background,
              border: Border.all(
                color:
                    VeriScanTheme.red.withAlpha((_pulseAnimation.value * 120).toInt()),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: VeriScanTheme.red
                      .withAlpha((_pulseAnimation.value * 60).toInt()),
                  blurRadius: 50,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/hub', (_) => false),
                  ),
                ),
                const Spacer(),
                // ── X Icon ──
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VeriScanTheme.red.withAlpha(20),
                      border: Border.all(color: VeriScanTheme.red, width: 3),
                      boxShadow: NeonStyles.redGlow,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: VeriScanTheme.red, size: 64),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'DANGER',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: VeriScanTheme.red,
                    letterSpacing: 4,
                    shadows: NeonStyles.textGlow(VeriScanTheme.red),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Spectral signature DOES NOT match\nany verified medicine in the database.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                // ── Buttons ──
                GlowingButton(
                  label: 'REPORT FRAUD',
                  icon: Icons.report_rounded,
                  type: GlowButtonType.danger,
                  onPressed: () => Navigator.pushNamed(context, '/report-location'),
                ),
                const SizedBox(height: 16),
                GlowingButton(
                  label: 'SCAN AGAIN',
                  icon: Icons.refresh_rounded,
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
    );
  }
}
