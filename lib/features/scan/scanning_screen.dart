import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ble_service.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _spectrumController;
  late Animation<double> _pulseAnimation;

  // Status shown on screen
  String _statusLine1 = 'Capturing Spectral Data...';
  String _statusLine2 = 'Hold device steady against tablet';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _spectrumController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysis();
    });
  }

  Future<void> _runAnalysis() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final ble = Provider.of<BleService>(context, listen: false);

    if (ble.rawBleString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sensor data. Connect ESP32 first.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
      return;
    }

    if (ble.selectedMedicine.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a medicine before scanning.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
      return;
    }

    final result = await ble.analyzeWithAI();
    if (!mounted) return;

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result['error']}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) Navigator.pop(context);
      return;
    }

    final isAuthentic = result['is_authentic'] == true;

    // Pass exact keys that result screens expect
    final args = {
      'resultCode': result['verdict'] ?? '',
      'similarity': (result['similarity'] as num?)?.toDouble() ?? 0.0,
      'confidence': (result['confidence'] as num?)?.toDouble() ?? 0.0,
      'verdict': result['verdict'] ?? '',
      'message': result['message'] ?? '',
      'detected_medicine': result['detected_medicine'] ?? '',
      'selected_medicine': ble.selectedMedicine,
      'is_fresh': result['is_fresh'] ?? false,
      'medicine_matches': result['medicine_matches'] ?? true,
    };

    Navigator.pushReplacementNamed(
      context,
      isAuthentic ? '/result-authentic' : '/result-danger',
      arguments: args,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spectrumController.dispose();
    super.dispose();
  }

  void _setStatus(String line1, String line2) {
    if (!mounted) return;
    setState(() {
      _statusLine1 = line1;
      _statusLine2  = line2;
    });
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: NeonStyles.radialGlow(
          color: VeriScanTheme.cyan,
          radius: 0.5,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              const Spacer(),
              // ── Pulse Ring ──
              _buildPulseRing(),
              const SizedBox(height: 40),
              // ── Status Text ──
              Text(
                _statusLine1,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  shadows: NeonStyles.textGlow(VeriScanTheme.cyan),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusLine2,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              // ── Spectrum Bars ──
              _buildSpectrumBars(),
              const Spacer(),
              // ── Progress ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 4),
                  builder: (context, value, _) {
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white.withAlpha(10),
                            valueColor: AlwaysStoppedAnimation(VeriScanTheme.cyan),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            color: VeriScanTheme.cyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRing() {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulseRingPainter(
              progress: _pulseAnimation.value,
              color: VeriScanTheme.cyan,
            ),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VeriScanTheme.cyan.withAlpha(25),
              border: Border.all(color: VeriScanTheme.cyan, width: 2),
              boxShadow: NeonStyles.cyanGlow,
            ),
            child: const Icon(Icons.sensors_rounded,
                color: VeriScanTheme.cyan, size: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildSpectrumBars() {
    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: _spectrumController,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(14, (i) {
              final random = Random(i + (_spectrumController.value * 10).toInt());
              final height = 20.0 + random.nextDouble() * 50;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 8,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        VeriScanTheme.purple,
                        VeriScanTheme.cyan,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VeriScanTheme.cyan.withAlpha(80),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PulseRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final p = (progress + i * 0.33) % 1.0;
      final radius = 40 + p * 60;
      final paint = Paint()
        ..color = color.withAlpha(((1 - p) * 100).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter old) =>
      old.progress != progress;
}
