import 'dart:math';
import 'package:flutter/material.dart';

class ModernLoader extends StatefulWidget {
  final double size;
  final Color color;

  const ModernLoader({
    super.key,
    this.size = 60,
    this.color = Colors.black,
  });

  @override
  State<ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<ModernLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * pi,
            child: child,
          );
        },
        child: CustomPaint(
          painter: _LoaderPainter(widget.color),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final Color color;

  _LoaderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const totalDots = 12;
    final center = size.center(Offset.zero);
    final radius = size.width * 0.42;

    for (int i = 0; i < totalDots; i++) {
      final angle = (i / totalDots) * 2 * pi;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      final opacity = (i + 1) / totalDots;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y),
            width: size.width * 0.10,
            height: size.width * 0.23,
          ),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}