import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  final _dio = Dio();
  static const _storage = FlutterSecureStorage();

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

    // Wait for animation to run, then process
    Future.delayed(const Duration(seconds: 3), () => _process());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Core logic ────────────────────────────────────────────────────────────

  Future<void> _process() async {
    if (!mounted) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final bool isCodeA    = args?['isCodeA'] as bool? ?? false;
    final double similarity = args?['similarity'] as double? ?? 0.0;
    final List<double> values =
        (args?['values'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];

    if (isCodeA) {
      // CODE:A — skip API, counterfeit
      _navigate('/result-danger', {
        'resultCode': 'CODE:A',
        'similarity': similarity,
        'confidence': 0.0,
        'values': values,
      });
      return;
    }

    // Try real API first
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.post(
        'http://10.0.2.2:8000/scan/predict',
        data: {
          'values': values,
          'similarity': similarity,
        },
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final resultCode = response.data['result_code'] as String? ?? 'CODE:A';
      final confidence = (response.data['confidence'] as num?)?.toDouble() ?? 0.0;

      final route = (resultCode == 'CODE:B' || resultCode == 'CODE:C')
          ? '/result-authentic'
          : '/result-danger';

      _navigate(route, {
        'resultCode': resultCode,
        'similarity': similarity,
        'confidence': confidence,
        'values': values,
      });
    } catch (_) {
      // API unavailable — local fallback
      final result = _localFallback(values, similarity);
      _navigate(result['route'] as String, result['args'] as Map<String, dynamic>);
    }
  }

  Map<String, dynamic> _localFallback(List<double> values, double similarity) {
    final avg = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    String resultCode;
    double confidence;
    if (avg > 0.6) {
      resultCode = 'CODE:B';
      confidence = 0.92;
    } else if (avg > 0.4) {
      resultCode = 'CODE:C';
      confidence = 0.85;
    } else {
      resultCode = 'CODE:A';
      confidence = 0.95;
    }

    final route = (resultCode == 'CODE:B' || resultCode == 'CODE:C')
        ? '/result-authentic'
        : '/result-danger';

    return {
      'route': route,
      'args': {
        'resultCode': resultCode,
        'similarity': similarity,
        'confidence': confidence,
        'values': values,
      },
    };
  }

  void _navigate(String route, Map<String, dynamic> args) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route, arguments: args);
  }

  // ── UI (unchanged) ────────────────────────────────────────────────────────

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
