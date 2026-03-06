import 'package:flutter/material.dart';

import '../utils/brand_tokens.dart';

/// Animated shimmer effect used as a loading indicator for AI operations.
///
/// Displays a horizontal gradient that slides left to right, repeating
/// continuously until removed from the widget tree.
class AIShimmerView extends StatefulWidget {
  final double width;
  final double height;

  const AIShimmerView({
    super.key,
    this.width = double.infinity,
    this.height = 20,
  });

  @override
  State<AIShimmerView> createState() => _AIShimmerViewState();
}

class _AIShimmerViewState extends State<AIShimmerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Brand.radiusField),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: [
                Brand.primaryTint,
                Brand.primary.withValues(alpha: 0.20),
                Brand.primaryTint,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
