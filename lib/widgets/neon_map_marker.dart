import 'package:flutter/material.dart';
import '../core/neon_styles.dart';

class NeonMapMarker extends StatefulWidget {
  final Color color;
  final double size;
  final bool pulse;
  final String? label;

  const NeonMapMarker({
    super.key,
    required this.color,
    this.size = 20,
    this.pulse = true,
    this.label,
  });

  @override
  State<NeonMapMarker> createState() => _NeonMapMarkerState();
}

class _NeonMapMarkerState extends State<NeonMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
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
      animation: _animation,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: NeonStyles.neonShadow(
                  widget.color,
                  blur: 15 * _animation.value,
                  spread: 2 * _animation.value,
                ),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.label!,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
