import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../utils/brand_tokens.dart';

/// Displays a looping onboarding video and starts or stops playback based on
/// whether the page is currently active.
class OnboardingVideoView extends StatefulWidget {
  const OnboardingVideoView({
    super.key,
    required this.assetPath,
    required this.isActive,
  });

  final String assetPath;
  final bool isActive;

  @override
  State<OnboardingVideoView> createState() => _OnboardingVideoViewState();
}

class _OnboardingVideoViewState extends State<OnboardingVideoView> {
  late final VideoPlayerController _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath);
    _initializeFuture = _controller.initialize().then((_) async {
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      if (widget.isActive) {
        await _controller.play();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant OnboardingVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) {
      return;
    }

    if (!_controller.value.isInitialized) {
      return;
    }

    if (widget.isActive) {
      _controller.seekTo(Duration.zero);
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Brand.cream,
      child: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (_controller.value.isInitialized) {
            return ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            );
          }

          return Center(
            child: CircularProgressIndicator(
              color: Brand.primary.withValues(alpha: 0.85),
            ),
          );
        },
      ),
    );
  }
}
