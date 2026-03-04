import 'package:flutter/material.dart';
import 'theme.dart';

class NeonStyles {
  // ── Glow Shadows ──
  static List<BoxShadow> neonShadow(Color color, {double blur = 20, double spread = 2}) {
    return [
      BoxShadow(color: color.withAlpha(100), blurRadius: blur, spreadRadius: spread),
      BoxShadow(color: color.withAlpha(50), blurRadius: blur * 2, spreadRadius: spread / 2),
    ];
  }

  static List<BoxShadow> get cyanGlow => neonShadow(VeriScanTheme.cyan);
  static List<BoxShadow> get purpleGlow => neonShadow(VeriScanTheme.purple);
  static List<BoxShadow> get greenGlow => neonShadow(VeriScanTheme.green);
  static List<BoxShadow> get redGlow => neonShadow(VeriScanTheme.red);

  // ── Gradient Borders ──
  static BoxDecoration neonBorderDecoration({
    required Gradient gradient,
    double borderWidth = 1.5,
    double radius = 20,
    Color? fillColor,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      color: fillColor,
    );
  }

  // ── Glass Decoration ──
  static BoxDecoration glassDecoration({
    double radius = 20,
    Color? borderColor,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: VeriScanTheme.cardFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withAlpha(25),
        width: borderWidth,
      ),
    );
  }

  // ── Radial Background Glow ──
  static BoxDecoration radialGlow({
    Color color = const Color(0xFF8A2BE2),
    double radius = 0.6,
  }) {
    return BoxDecoration(
      gradient: RadialGradient(
        colors: [color.withAlpha(40), Colors.transparent],
        radius: radius,
      ),
    );
  }

  // ── Neon Text Shadow ──
  static List<Shadow> textGlow(Color color) {
    return [
      Shadow(color: color.withAlpha(150), blurRadius: 10),
      Shadow(color: color.withAlpha(80), blurRadius: 30),
    ];
  }
}
