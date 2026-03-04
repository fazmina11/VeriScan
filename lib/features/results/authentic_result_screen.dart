import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glowing_button.dart';

class AuthenticResultScreen extends StatefulWidget {
  const AuthenticResultScreen({super.key});

  @override
  State<AuthenticResultScreen> createState() => _AuthenticResultScreenState();
}

class _AuthenticResultScreenState extends State<AuthenticResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

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

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: VeriScanTheme.background,
              border: Border.all(
                color:
                    VeriScanTheme.green.withAlpha((_glowAnimation.value * 80).toInt()),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: VeriScanTheme.green
                      .withAlpha((_glowAnimation.value * 50).toInt()),
                  blurRadius: 40,
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
                    onPressed: () =>
                        Navigator.pushNamedAndRemoveUntil(context, '/hub', (_) => false),
                  ),
                ),
                const Spacer(),
                // ── Checkmark ──
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VeriScanTheme.green.withAlpha(20),
                      border: Border.all(color: VeriScanTheme.green, width: 3),
                      boxShadow: NeonStyles.greenGlow,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: VeriScanTheme.green, size: 64),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'AUTHENTIC',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: VeriScanTheme.green,
                    letterSpacing: 4,
                    shadows: NeonStyles.textGlow(VeriScanTheme.green),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This tablet matches the verified\nspectral signature database.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                // ── Buttons ──
                GlowingButton(
                  label: 'GENERATE CERTIFICATE',
                  icon: Icons.workspace_premium_rounded,
                  type: GlowButtonType.success,
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                GlowingButton(
                  label: 'SAVE TO HISTORY',
                  icon: Icons.save_rounded,
                  onPressed: () {},
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
