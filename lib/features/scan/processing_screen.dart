import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    // Simulate processing — navigate to result after 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Randomly pick authentic or danger for demo
        final isAuthentic = Random().nextBool();
        Navigator.pushReplacementNamed(
          context,
          isAuthentic ? '/result-authentic' : '/result-danger',
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: NeonStyles.radialGlow(
          color: VeriScanTheme.purple,
          radius: 0.4,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Neon Loader ──
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _NeonLoaderPainter(
                        angle: _rotateAnimation.value,
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: VeriScanTheme.primaryGradient,
                        boxShadow: NeonStyles.purpleGlow,
                      ),
                      child: const Icon(Icons.analytics_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Analyzing Spectral Signature...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  shadows: NeonStyles.textGlow(VeriScanTheme.purple),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Comparing against verified database',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeonLoaderPainter extends CustomPainter {
  final double angle;
  _NeonLoaderPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withAlpha(15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Neon arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle,
        endAngle: angle + pi,
        colors: [
          VeriScanTheme.purple.withAlpha(0),
          VeriScanTheme.purple,
          VeriScanTheme.cyan,
          VeriScanTheme.cyan.withAlpha(0),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle,
      pi * 1.2,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NeonLoaderPainter old) => old.angle != angle;
}
