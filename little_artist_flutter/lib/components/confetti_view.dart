import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/brand_tokens.dart';

/// Celebration particle animation that spawns colorful confetti pieces.
///
/// When [isPlaying] transitions to `true`, spawns 30-50 colored particles
/// that fall with gravity and slight horizontal drift over ~2 seconds.
class ConfettiView extends StatefulWidget {
  final bool isPlaying;

  const ConfettiView({
    super.key,
    required this.isPlaying,
  });

  @override
  State<ConfettiView> createState() => _ConfettiViewState();
}

class _ConfettiViewState extends State<ConfettiView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  static const List<Color> _colors = [
    Brand.primary,
    Brand.sage,
    Brand.sky,
    Brand.lavender,
    Brand.dustyRose,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _particles = [];
          });
        }
      });

    if (widget.isPlaying) {
      _spawnParticles();
    }
  }

  @override
  void didUpdateWidget(ConfettiView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    final count = 30 + _random.nextInt(21); // 30-50 particles
    _particles = List.generate(count, (_) {
      return _ConfettiParticle(
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.2, // start above top
        velocityX: (_random.nextDouble() - 0.5) * 0.4, // horizontal drift
        velocityY: 0.3 + _random.nextDouble() * 0.5, // downward speed
        size: 4.0 + _random.nextDouble() * 4.0, // 4-8px
        color: _colors[_random.nextInt(_colors.length)],
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// MARK: - Particle Data
// ---------------------------------------------------------------------------

class _ConfettiParticle {
  final double x;
  final double y;
  final double velocityX;
  final double velocityY;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  const _ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// ---------------------------------------------------------------------------
// MARK: - Painter
// ---------------------------------------------------------------------------

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out in the last 30% of the animation
    final opacity = progress > 0.7 ? (1.0 - progress) / 0.3 : 1.0;

    for (final particle in particles) {
      // Apply gravity (acceleration over time)
      final gravity = 0.5 * progress * progress;
      final currentX =
          (particle.x + particle.velocityX * progress) * size.width;
      final currentY =
          (particle.y + particle.velocityY * progress + gravity) * size.height;

      if (currentY > size.height || currentX < 0 || currentX > size.width) {
        continue;
      }

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress);

      // Draw a small rectangle for confetti piece
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          Radius.circular(particle.size * 0.15),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
