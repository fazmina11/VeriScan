import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  final _dio = Dio();
  static const _storage = FlutterSecureStorage();

  // Route data
  String _resultCode = '';
  double _similarity = 0.0;
  double _confidence = 0.0;

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _readArgs());
  }

  void _readArgs() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args == null) return;
    setState(() {
      _resultCode = args['resultCode'] as String? ?? '';
      _similarity = (args['similarity'] as num?)?.toDouble() ?? 0.0;
      _confidence = (args['confidence'] as num?)?.toDouble() ?? 0.0;
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.post(
        'http://10.0.2.2:8000/scan/save',
        data: {
          'medicine_name': 'Unknown',
          'result_code': _resultCode,
          'similarity_score': _similarity,
          'ai_confidence': _confidence,
          'gemini_report': '',
        },
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan saved!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save — check connection.')),
        );
      }
    }
  }

  String _fmt(double v) => (v * 100).toStringAsFixed(1);

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
                // Result code badge
                if (_resultCode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: VeriScanTheme.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: VeriScanTheme.green.withAlpha(80)),
                    ),
                    child: Text(
                      _resultCode,
                      style: TextStyle(
                        color: VeriScanTheme.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'This tablet matches the verified\nspectral signature database.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                // ── Scores ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildScoreBadge(
                        'Spectral Match', '${_fmt(_similarity)}%', VeriScanTheme.cyan),
                    const SizedBox(width: 16),
                    _buildScoreBadge(
                        'AI Confidence', '${_fmt(_confidence)}%', VeriScanTheme.green),
                  ],
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
                  onPressed: _saveToHistory,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
