import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_map_marker.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  String _selectedFilter = '30d';

  final List<_MapPoint> _points = [
    _MapPoint(0.2, 0.3, VeriScanTheme.green, 'Safe Pharmacy'),
    _MapPoint(0.5, 0.25, VeriScanTheme.red, 'Fraud Report'),
    _MapPoint(0.7, 0.4, VeriScanTheme.green, 'Safe Pharmacy'),
    _MapPoint(0.3, 0.55, VeriScanTheme.orange, 'Under Review'),
    _MapPoint(0.8, 0.6, VeriScanTheme.red, 'Fraud Report'),
    _MapPoint(0.15, 0.7, VeriScanTheme.green, 'Safe Pharmacy'),
    _MapPoint(0.6, 0.75, VeriScanTheme.red, 'Fraud Report'),
    _MapPoint(0.45, 0.45, VeriScanTheme.green, 'Safe Pharmacy'),
    _MapPoint(0.35, 0.8, VeriScanTheme.orange, 'Under Review'),
    _MapPoint(0.9, 0.35, VeriScanTheme.green, 'Safe Pharmacy'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Dark Map Background ──
          Container(
            decoration: const BoxDecoration(color: Color(0xFF0A0C10)),
            child: CustomPaint(
              painter: _DarkMapPainter(),
              size: Size.infinite,
            ),
          ),

          // ── Heatmap Overlay ──
          CustomPaint(
            painter: _HeatmapPainter(points: _points),
            size: Size.infinite,
          ),

          // ── Map Markers ──
          ..._points.map((p) => _buildMarker(context, p)),

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
                  Expanded(
                    child: Text(
                      'Community Shield',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        shadows: NeonStyles.textGlow(VeriScanTheme.cyan),
                      ),
                    ),
                  ),
                  // Filter
                  GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    borderRadius: 12,
                    child: const Icon(Icons.filter_list_rounded,
                        color: VeriScanTheme.cyan, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // ── Filter Toggle ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            right: 16,
            child: _buildFilterToggle(),
          ),

          // ── Legend ──
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(BuildContext context, _MapPoint point) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: point.x * size.width - 10,
      top: point.y * size.height - 10,
      child: NeonMapMarker(
        color: point.color,
        size: 20,
        pulse: point.color == VeriScanTheme.red,
      ),
    );
  }

  Widget _buildFilterToggle() {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 14,
      child: Row(
        children: [
          _buildFilterChip('7d', 'Last 7 Days'),
          _buildFilterChip('30d', 'Last 30 Days'),
          _buildFilterChip('all', 'All Time'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? VeriScanTheme.cyan.withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: VeriScanTheme.cyan.withAlpha(60))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? VeriScanTheme.cyan : VeriScanTheme.textMuted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(VeriScanTheme.green, 'Verified Safe'),
          _buildLegendItem(VeriScanTheme.red, 'Fraud Report'),
          _buildLegendItem(VeriScanTheme.orange, 'Under Review'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withAlpha(100), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: VeriScanTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MapPoint {
  final double x;
  final double y;
  final Color color;
  final String label;
  const _MapPoint(this.x, this.y, this.color, this.label);
}

class _DarkMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final roadPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.35), roadPaint);
    canvas.drawLine(Offset(size.width * 0.4, 0),
        Offset(size.width * 0.45, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.75, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeatmapPainter extends CustomPainter {
  final List<_MapPoint> points;
  _HeatmapPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in points) {
      if (p.color == VeriScanTheme.red) {
        final center = Offset(p.x * size.width, p.y * size.height);
        final gradient = RadialGradient(
          colors: [
            VeriScanTheme.red.withAlpha(25),
            VeriScanTheme.red.withAlpha(0),
          ],
        );
        final paint = Paint()
          ..shader = gradient
              .createShader(Rect.fromCircle(center: center, radius: 60));
        canvas.drawCircle(center, 60, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) => false;
}
