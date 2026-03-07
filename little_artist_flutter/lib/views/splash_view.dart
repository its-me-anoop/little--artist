import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../utils/brand_tokens.dart';

/// Full-screen splash view that plays the bundled splash video, fades out, and
/// then routes to onboarding or the main app.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final VideoPlayerController _controller;
  bool _hasHandledVideoEnd = false;
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/onboarding/splash.mov');
    _controller
      ..setVolume(0)
      ..addListener(_handleVideoProgress);

    _initializeAndPlay();
  }

  Future<void> _initializeAndPlay() async {
    try {
      await _controller.initialize();
      if (!mounted) {
        return;
      }
      setState(() {});
      await _controller.play();
    } catch (_) {
      await _navigateAfterSplash();
    }
  }

  void _handleVideoProgress() {
    if (_hasHandledVideoEnd || !_controller.value.isInitialized) {
      return;
    }

    final position = _controller.value.position;
    final duration = _controller.value.duration;
    if (duration == Duration.zero || position < duration) {
      return;
    }

    _hasHandledVideoEnd = true;
    _finishSplash();
  }

  Future<void> _finishSplash() async {
    if (!mounted) {
      return;
    }

    setState(() => _opacity = 0);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    if (!mounted) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasCompleted = prefs.getBool('hasCompletedOnboarding') ?? false;

    if (!mounted) {
      return;
    }

    if (hasCompleted) {
      context.go('/gallery');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleVideoProgress)
      ..pause()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Center(
          child: _controller.value.isInitialized
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(Brand.radiusCard),
                  child: SizedBox(
                    width: 250,
                    height: 350,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: 250, height: 350),
        ),
      ),
    );
  }
}
