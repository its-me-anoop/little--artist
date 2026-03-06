import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';
import '../../utils/color_hex.dart';

/// Cards that drift slowly across the screen with gentle floating motion.
class DriftCardsView extends StatefulWidget {
  const DriftCardsView({super.key});

  @override
  State<DriftCardsView> createState() => _DriftCardsViewState();
}

class _DriftCardsViewState extends State<DriftCardsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _icons = [
    Icons.palette,
    Icons.brush,
    Icons.auto_awesome,
    Icons.favorite,
    Icons.star,
  ];

  static const _cardWidth = 110.0;
  static const _cardHeight = 145.0;

  // Base positions for each card
  static const _basePositions = [
    Offset(-60, -50),
    Offset(70, -70),
    Offset(-40, 40),
    Offset(50, 50),
    Offset(0, -10),
  ];

  // Drift deltas (small movement range)
  static const _driftDeltas = [
    Offset(20, 15),
    Offset(-15, 20),
    Offset(18, -12),
    Offset(-20, -18),
    Offset(12, 20),
  ];

  // Rotation drift in radians
  static const _rotationDrifts = [0.08, -0.06, 0.05, -0.07, 0.04];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Brand.onboardingCardHeight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(_icons.length, (index) {
              // Use sine for smooth oscillation with per-card phase offset
              final phase = _controller.value * 2 * math.pi +
                  (index * math.pi * 0.4);
              final t = (math.sin(phase) + 1) / 2; // normalize 0..1

              final base = _basePositions[index];
              final delta = _driftDeltas[index];
              final dx = base.dx + delta.dx * t;
              final dy = base.dy + delta.dy * t;
              final rotation = _rotationDrifts[index] * math.sin(phase);

              final color =
                  Brand.avatarColors[index % Brand.avatarColors.length]
                      .toColor();

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: _cardWidth,
                    height: _cardHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(Brand.radiusCard),
                      boxShadow: Brand.cardShadow,
                    ),
                    child: Icon(
                      _icons[index],
                      color: Colors.white,
                      size: 34,
                    ),
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
