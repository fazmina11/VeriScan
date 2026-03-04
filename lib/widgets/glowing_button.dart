import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/neon_styles.dart';

enum GlowButtonType { primary, success, danger }

class GlowingButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final GlowButtonType type;
  final IconData? icon;
  final double width;

  const GlowingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = GlowButtonType.primary,
    this.icon,
    this.width = double.infinity,
  });

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Gradient get _gradient {
    switch (widget.type) {
      case GlowButtonType.success:
        return VeriScanTheme.successGradient;
      case GlowButtonType.danger:
        return VeriScanTheme.dangerGradient;
      case GlowButtonType.primary:
        return VeriScanTheme.primaryGradient;
    }
  }

  Color get _glowColor {
    switch (widget.type) {
      case GlowButtonType.success:
        return VeriScanTheme.green;
      case GlowButtonType.danger:
        return VeriScanTheme.red;
      case GlowButtonType.primary:
        return VeriScanTheme.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: NeonStyles.neonShadow(
              _glowColor,
              blur: 20 * _glowAnimation.value,
              spread: 1,
            ),
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
