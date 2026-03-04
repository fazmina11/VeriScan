import 'package:flutter/material.dart';
import '../core/neon_styles.dart';

class NeonContainer extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool pulse;

  const NeonContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.pulse = false,
  });

  @override
  State<NeonContainer> createState() => _NeonContainerState();
}

class _NeonContainerState extends State<NeonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final intensity = widget.pulse ? _pulseAnimation.value : 0.7;
        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: const Color(0xFF151820),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.glowColor.withAlpha((intensity * 180).toInt()),
              width: 1.5,
            ),
            boxShadow: NeonStyles.neonShadow(
              widget.glowColor,
              blur: 20 * intensity,
              spread: 1 * intensity,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
