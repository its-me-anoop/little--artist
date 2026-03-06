import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';
import '../../utils/color_hex.dart';

/// Cards arranged in a diamond pattern that pulse rhythmically.
class PulseCardsView extends StatefulWidget {
  const PulseCardsView({super.key});

  @override
  State<PulseCardsView> createState() => _PulseCardsViewState();
}

class _PulseCardsViewState extends State<PulseCardsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _icons = [
    Icons.palette,
    Icons.brush,
    Icons.auto_awesome,
    Icons.favorite,
    Icons.star,
  ];

  static const _cardSize = 100.0;

  // Diamond / cross positions
  static const _positions = [
    Offset(0, -70), // top
    Offset(80, 0), // right
    Offset(0, 70), // bottom
    Offset(-80, 0), // left
    Offset(0, 0), // center
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
              // Stagger: each card offset by 200ms in the 2000ms cycle
              final phaseOffset = index * 0.1; // 200ms / 2000ms
              final curved = CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  phaseOffset,
                  (phaseOffset + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeInOut,
                ),
              );

              final scale = 0.9 + 0.2 * curved.value;
              final pos = _positions[index];

              final color =
                  Brand.avatarColors[index % Brand.avatarColors.length]
                      .toColor();

              return Transform.translate(
                offset: pos,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: _cardSize,
                    height: _cardSize * 1.33,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(Brand.radiusCard),
                      boxShadow: Brand.cardShadow,
                    ),
                    child: Icon(
                      _icons[index],
                      color: Colors.white,
                      size: 32,
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
