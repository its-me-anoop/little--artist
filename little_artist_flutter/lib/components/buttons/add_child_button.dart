import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Dashed circle button for adding a new child profile.
class AddChildButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddChildButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: Brand.avatarSize,
        height: Brand.avatarSize,
        child: CustomPaint(
          painter: _DashedCirclePainter(color: Brand.warmGray),
          child: const Center(
            child: Icon(
              Icons.add,
              size: 24,
              color: Brand.warmGray,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a dashed circle outline.
class _DashedCirclePainter extends CustomPainter {
  final Color color;

  static const double _strokeWidth = 1.5;
  static const double _dashLength = 6;
  static const double _gapLength = 4;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - (_strokeWidth / 2);
    final circumference = 2 * pi * radius;
    final dashCount = (circumference / (_dashLength + _gapLength)).floor();
    final dashAngle = (_dashLength / circumference) * 2 * pi;
    final gapAngle = (2 * pi - (dashCount * dashAngle)) / dashCount;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
