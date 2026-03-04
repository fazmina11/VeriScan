import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';
import '../../widgets/neon_map_marker.dart';

class MapPinScreen extends StatefulWidget {
  const MapPinScreen({super.key});

  @override
  State<MapPinScreen> createState() => _MapPinScreenState();
}

class _MapPinScreenState extends State<MapPinScreen> {
  Offset? _pinOffset;
  bool _showPharmacyCard = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Dark Neon Map Background ──
          GestureDetector(
            onTapDown: (details) {
              setState(() {
                _pinOffset = details.localPosition;
                _showPharmacyCard = true;
              });
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A0C10),
              ),
              child: CustomPaint(
                painter: _DarkMapPainter(),
                size: Size.infinite,
              ),
            ),
          ),

          // ── Placed Pin ──
          if (_pinOffset != null)
            Positioned(
              left: _pinOffset!.dx - 15,
              top: _pinOffset!.dy - 15,
              child: const NeonMapMarker(
                color: VeriScanTheme.red,
                size: 30,
                pulse: true,
              ),
            ),

          // ── Top Bar ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    borderRadius: 12,
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Drop Pin on Location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),

          // ── Pharmacy Card ──
          if (_showPharmacyCard)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: GlassCard(
                borderColor: VeriScanTheme.red.withAlpha(60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VeriScanTheme.red.withAlpha(25),
                          ),
                          child: const Icon(Icons.local_pharmacy_rounded,
                              color: VeriScanTheme.red, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Khan Medical Store',
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text('Block 7, Clifton, Karachi',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: VeriScanTheme.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '3 Fraud Reports',
                        style: TextStyle(
                          color: VeriScanTheme.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Confirm Button ──
          if (_pinOffset != null)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: GlowingButton(
                label: 'CONFIRM LOCATION',
                icon: Icons.check_circle_rounded,
                type: GlowButtonType.danger,
                onPressed: () =>
                    Navigator.pushNamed(context, '/report-evidence'),
              ),
            ),

          // ── Hint ──
          if (_pinOffset == null)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  borderRadius: 30,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          color: VeriScanTheme.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to drop a pin',
                        style: TextStyle(
                          color: VeriScanTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DarkMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw grid lines to simulate a dark map
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some "road" lines
    final roadPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
        Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.35),
        roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.4, 0),
        Offset(size.width * 0.45, size.height),
        roadPaint);
    canvas.drawLine(
        Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.65),
        roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.75, 0),
        Offset(size.width * 0.7, size.height),
        roadPaint);

    // Diagonal roads
    final diagonalPaint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), diagonalPaint);
    canvas.drawLine(
        Offset(size.width * 0.2, 0),
        Offset(size.width * 0.8, size.height),
        diagonalPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
