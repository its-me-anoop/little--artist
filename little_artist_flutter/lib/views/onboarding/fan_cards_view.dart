import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';
import '../../utils/color_hex.dart';

/// Cards that fan out from a central stack with elastic rotation.
class FanCardsView extends StatefulWidget {
  const FanCardsView({super.key});

  @override
  State<FanCardsView> createState() => _FanCardsViewState();
}

class _FanCardsViewState extends State<FanCardsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _icons = [
    Icons.palette,
    Icons.brush,
    Icons.auto_awesome,
    Icons.favorite,
    Icons.star,
  ];

  static const _cardWidth = 120.0;
  static const _cardHeight = 160.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
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
              final delay = index * 0.067; // ~100ms stagger over 1500ms
              final curved = CurvedAnimation(
                parent: _controller,
                curve: Interval(delay, 1.0, curve: Curves.elasticOut),
              );

              // Fan angle: -30 to +30 degrees
              final targetAngle =
                  (-30.0 + (60.0 / (_icons.length - 1)) * index) *
                      (math.pi / 180);
              final angle = targetAngle * curved.value;

              // Translate outward from center
              final targetX = (index - 2) * 30.0;
              final targetY = -((2 - (index - 2).abs()) * 12.0);
              final dx = targetX * curved.value;
              final dy = targetY * curved.value;

              final color =
                  Brand.avatarColors[index % Brand.avatarColors.length]
                      .toColor();

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: angle,
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
                      size: 36,
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
