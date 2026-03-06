import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';
import '../../utils/color_hex.dart';

/// Cards that drop in from above the screen with a bouncy stagger.
class DropCardsView extends StatefulWidget {
  const DropCardsView({super.key});

  @override
  State<DropCardsView> createState() => _DropCardsViewState();
}

class _DropCardsViewState extends State<DropCardsView>
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

  // Final resting positions (loose grid)
  static const _restPositions = [
    Offset(-80, -60),
    Offset(60, -80),
    Offset(-30, 30),
    Offset(80, 20),
    Offset(0, -20),
  ];

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
              final delay = index * 0.1; // 150ms stagger over 1500ms
              final curved = CurvedAnimation(
                parent: _controller,
                curve: Interval(delay, 1.0, curve: Curves.bounceOut),
              );

              final rest = _restPositions[index];
              final dy = -300 + (300 + rest.dy) * curved.value;
              final dx = rest.dx * curved.value;

              final color =
                  Brand.avatarColors[index % Brand.avatarColors.length]
                      .toColor();

              return Transform.translate(
                offset: Offset(dx, dy),
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
              );
            }),
          );
        },
      ),
    );
  }
}
