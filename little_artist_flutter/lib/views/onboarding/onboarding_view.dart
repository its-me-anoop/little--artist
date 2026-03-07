import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../services/haptic_service.dart';
import '../../utils/brand_tokens.dart';
import '../children/add_child_view.dart';
import 'onboarding_video_view.dart';

/// Five-page onboarding flow ported from the SwiftUI implementation.
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      titleTop: 'Preserve the',
      titleHighlight: 'Magic',
      description:
          "Never lose a precious drawing again. Digitally archive and share your child's masterpieces in one safe place.",
      color: Brand.primary,
      videoAsset: 'assets/onboarding/paint.mov',
    ),
    _OnboardingPageData(
      titleTop: 'Capture Every',
      titleHighlight: 'Creation',
      description:
          "Snap photos of drawings, paintings, and crafts. Build a beautiful gallery of your child's creativity over time.",
      color: Brand.sage,
      videoAsset: 'assets/onboarding/capture.mov',
    ),
    _OnboardingPageData(
      titleTop: 'AI-Powered',
      titleHighlight: 'Captions',
      description:
          'Let AI generate fun titles and captions for each artwork, capturing the magic and story behind every creation.',
      color: Brand.sky,
      videoAsset: 'assets/onboarding/magic.MP4',
    ),
    _OnboardingPageData(
      titleTop: 'Add Voice',
      titleHighlight: 'Notes',
      description:
          'Let your child record a voice note describing their artwork. Preserve their words and imagination forever.',
      color: Brand.lavender,
      videoAsset: 'assets/onboarding/voice.mov',
    ),
    _OnboardingPageData(
      titleTop: 'Share &',
      titleHighlight: 'Celebrate',
      description:
          "Share artwork with family and friends. Let everyone celebrate your little artist's wonderful creations.",
      color: Brand.dustyRose,
      videoAsset: 'assets/onboarding/share.mov',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isTablet => MediaQuery.sizeOf(context).shortestSide >= 600;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage() async {
    HapticService.medium();
    if (_currentPage < _pages.length - 1) {
      await _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
      );
      return;
    }

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) =>
            _OnboardingSignInScreen(accentColor: _pages[_currentPage].color),
      ),
    );

    if (!mounted || completed != true) {
      return;
    }

    await _finishOnboardingWithOptionalAddChild();
  }

  Future<void> _skipOnboarding() async {
    await _setHasCompletedOnboarding();
    if (!mounted) {
      return;
    }
    context.go('/gallery');
  }

  Future<void> _finishOnboardingWithOptionalAddChild() async {
    final db = ref.read(databaseProvider);
    final childCount = await db.childDao.getChildCount();

    if (!mounted) {
      return;
    }

    if (childCount == 0) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const AddChildView(),
        ),
      );
    }

    await _setHasCompletedOnboarding();
    if (!mounted) {
      return;
    }
    context.go('/gallery');
  }

  Future<void> _setHasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
  }

  void _handlePageChanged(int index) {
    setState(() => _currentPage = index);
    HapticService.selection();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _AnimatedBackground(pageIndex: _currentPage, accentColor: page.color),
          if (_isTablet) _buildTabletLayout(page) else _buildPhoneLayout(),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 176),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _OnboardingVideoCard(
                        accentColor: page.color,
                        child: OnboardingVideoView(
                          assetPath: page.videoAsset,
                          isActive: _currentPage == index,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildTitleSection(
                        page,
                        textAlign: TextAlign.center,
                        alignment: CrossAxisAlignment.center,
                      ),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(
                        page,
                        textAlign: TextAlign.center,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 36),
              child: _SkipButton(
                visible: _currentPage < _pages.length - 1,
                onPressed: _skipOnboarding,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PageIndicators(
                    pageCount: _pages.length,
                    currentPage: _currentPage,
                    activeColor: _pages[_currentPage].color,
                  ),
                  const SizedBox(height: 24),
                  _PrimaryOnboardingButton(
                    label: _currentPage < _pages.length - 1
                        ? 'Next'
                        : 'Get Started',
                    color: _pages[_currentPage].color,
                    showArrow: _currentPage < _pages.length - 1,
                    onPressed: _goToNextPage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(_OnboardingPageData page) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _handlePageChanged,
                itemBuilder: (context, index) {
                  final entry = _pages[index];
                  return _OnboardingVideoCard(
                    accentColor: entry.color,
                    child: OnboardingVideoView(
                      assetPath: entry.videoAsset,
                      isActive: _currentPage == index,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 40, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      _SkipButton(
                        visible: _currentPage < _pages.length - 1,
                        onPressed: _skipOnboarding,
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildTitleSection(
                    page,
                    textAlign: TextAlign.start,
                    alignment: CrossAxisAlignment.start,
                  ),
                  const SizedBox(height: 20),
                  _buildDescriptionSection(page, textAlign: TextAlign.start),
                  const SizedBox(height: 40),
                  _PageIndicators(
                    pageCount: _pages.length,
                    currentPage: _currentPage,
                    activeColor: _pages[_currentPage].color,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 320,
                    child: _PrimaryOnboardingButton(
                      label: _currentPage < _pages.length - 1
                          ? 'Next'
                          : 'Get Started',
                      color: _pages[_currentPage].color,
                      showArrow: _currentPage < _pages.length - 1,
                      onPressed: _goToNextPage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(
    _OnboardingPageData page, {
    required TextAlign textAlign,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        _CrayonTransform(
          rotationDegrees: -1.0,
          scale: 1.01,
          offset: const Offset(0.6, -0.8),
          child: Text(
            page.titleTop,
            textAlign: textAlign,
            style: _roundedDisplayStyle(color: Brand.charcoal),
          ),
        ),
        const SizedBox(height: 4),
        _CrayonTransform(
          rotationDegrees: 1.2,
          scale: 0.995,
          offset: const Offset(-0.8, 0.4),
          child: Text(
            page.titleHighlight,
            textAlign: textAlign,
            style: _roundedDisplayStyle(color: page.color),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(
    _OnboardingPageData page, {
    required TextAlign textAlign,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Padding(
      padding: padding,
      child: _CrayonTransform(
        rotationDegrees: 0.5,
        scale: 1.0,
        offset: const Offset(0.2, 0.2),
        child: Text(
          page.description,
          textAlign: textAlign,
          style: _roundedTitleThreeStyle(
            color: Brand.warmGray,
          ).copyWith(height: 1.25),
        ),
      ),
    );
  }
}

class _OnboardingSignInScreen extends ConsumerStatefulWidget {
  const _OnboardingSignInScreen({required this.accentColor});

  final Color accentColor;

  @override
  ConsumerState<_OnboardingSignInScreen> createState() =>
      _OnboardingSignInScreenState();
}

class _OnboardingSignInScreenState
    extends ConsumerState<_OnboardingSignInScreen> {
  bool _isSigningIn = false;

  Future<void> _signInWithApple() async {
    if (_isSigningIn) {
      return;
    }

    setState(() => _isSigningIn = true);
    final authService = ref.read(firebaseAuthServiceProvider);
    final success = await authService.signInWithApple();
    if (!mounted) {
      return;
    }

    setState(() => _isSigningIn = false);

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final message = authService.authError;
    if (message == null || message.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _continueWithoutSignIn() async {
    if (_isSigningIn) {
      return;
    }

    setState(() => _isSigningIn = true);
    final authService = ref.read(firebaseAuthServiceProvider);
    await authService.signInAnonymously();
    if (!mounted) {
      return;
    }

    setState(() => _isSigningIn = false);

    if (authService.currentUser != null) {
      Navigator.of(context).pop(true);
      return;
    }

    final message = authService.authError;
    if (message == null || message.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: _isSigningIn
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
        ],
      ),
      body: Stack(
        children: [
          _AnimatedBackground(pageIndex: 4, accentColor: widget.accentColor),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Column(
                children: [
                  const Spacer(),
                  Image.asset(
                    'assets/onboarding/launch_fox.png',
                    width: 132,
                    height: 132,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  _CrayonTransform(
                    rotationDegrees: -1.1,
                    scale: 1.01,
                    offset: const Offset(0.4, -0.4),
                    child: Text(
                      'Sign In to Sync Across Devices',
                      textAlign: TextAlign.center,
                      style: _roundedDisplayStyle(color: Brand.charcoal),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _CrayonTransform(
                    rotationDegrees: 0.4,
                    scale: 1.0,
                    offset: const Offset(-0.2, 0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Use Sign in with Apple to access your account on a new device. You can also continue without signing in.',
                        textAlign: TextAlign.center,
                        style: _roundedTitleThreeStyle(
                          color: Brand.warmGray,
                        ).copyWith(height: 1.25),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _PrimaryDarkButton(
                    label: 'Sign in with Apple',
                    isBusy: _isSigningIn,
                    onPressed: _signInWithApple,
                  ),
                  const SizedBox(height: 16),
                  _SecondaryOnboardingButton(
                    label: 'Continue without sign in',
                    onPressed: _continueWithoutSignIn,
                    enabled: !_isSigningIn,
                  ),
                  if (_isSigningIn) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({
    required this.pageIndex,
    required this.accentColor,
  });

  final int pageIndex;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Brand.cream,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final large = width * 1.5;
          final medium = width * 1.2;

          return Stack(
            children: [
              _BlurredOrb(
                size: large,
                color: accentColor.withValues(alpha: 0.15),
                sigma: 60,
                duration: const Duration(milliseconds: 1500),
                offset: Offset(
                  pageIndex.isEven ? -width / 4 : width / 4,
                  pageIndex % 3 == 0 ? -height / 4 : height / 4,
                ),
              ),
              _BlurredOrb(
                size: medium,
                color: accentColor.withValues(alpha: 0.10),
                sigma: 80,
                duration: const Duration(milliseconds: 2000),
                offset: Offset(
                  pageIndex.isEven ? width / 3 : -width / 3,
                  pageIndex % 3 == 0 ? height / 3 : -height / 3,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BlurredOrb extends StatelessWidget {
  const _BlurredOrb({
    required this.size,
    required this.color,
    required this.sigma,
    required this.duration,
    required this.offset,
  });

  final double size;
  final Color color;
  final double sigma;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: duration,
      curve: Curves.easeInOut,
      offset: Offset(offset.dx / size, offset.dy / size),
      child: Center(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _OnboardingVideoCard extends StatelessWidget {
  const _OnboardingVideoCard({required this.accentColor, required this.child});

  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: AspectRatio(aspectRatio: 1, child: child),
      ),
    );
  }
}

class _PrimaryOnboardingButton extends StatelessWidget {
  const _PrimaryOnboardingButton({
    required this.label,
    required this.color,
    required this.showArrow,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool showArrow;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return _CrayonTransform(
      rotationDegrees: -0.9,
      scale: 1.0,
      offset: const Offset(0.4, 0.3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.92), color],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: _roundedTitleTwoStyle(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_right_alt,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryDarkButton extends StatelessWidget {
  const _PrimaryDarkButton({
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return _CrayonTransform(
      rotationDegrees: -0.8,
      scale: 1.0,
      offset: const Offset(0.2, 0.2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Brand.charcoal.withValues(alpha: 0.96), Brand.charcoal],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Brand.charcoal.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: isBusy ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apple, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    isBusy ? 'Signing in...' : label,
                    style: _roundedTitleTwoStyle(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryOnboardingButton extends StatelessWidget {
  const _SecondaryOnboardingButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final Future<void> Function() onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _CrayonTransform(
      rotationDegrees: 0.6,
      scale: 1.0,
      offset: const Offset(-0.3, 0.1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Brand.primary.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  label,
                  style: _roundedTitleThreeStyle(
                    color: Brand.primary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.pageCount,
    required this.currentPage,
    required this.activeColor,
  });

  final int pageCount;
  final int currentPage;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Transform.scale(
            scale: isActive ? 1.2 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: isActive ? 12 : 8,
              height: isActive ? 12 : 8,
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor
                    : Brand.warmGray.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.visible, required this.onPressed});

  final bool visible;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !visible,
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            'Skip',
            style: _roundedSubheadlineStyle(color: Brand.primary),
          ),
        ),
      ),
    );
  }
}

class _CrayonTransform extends StatelessWidget {
  const _CrayonTransform({
    required this.child,
    required this.rotationDegrees,
    required this.scale,
    required this.offset,
  });

  final Widget child;
  final double rotationDegrees;
  final double scale;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotationDegrees * (math.pi / 180),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.titleTop,
    required this.titleHighlight,
    required this.description,
    required this.color,
    required this.videoAsset,
  });

  final String titleTop;
  final String titleHighlight;
  final String description;
  final Color color;
  final String videoAsset;
}

TextStyle _roundedDisplayStyle({required Color color}) {
  return TextStyle(
    color: color,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    fontFamily: _roundedSystemFontFamily(),
    fontFamilyFallback: _roundedSystemFallbacks,
    height: 1.0,
  );
}

TextStyle _roundedTitleTwoStyle({required Color color}) {
  return TextStyle(
    color: color,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: _roundedSystemFontFamily(),
    fontFamilyFallback: _roundedSystemFallbacks,
    height: 1.0,
  );
}

TextStyle _roundedTitleThreeStyle({required Color color}) {
  return TextStyle(
    color: color,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontFamily: _roundedSystemFontFamily(),
    fontFamilyFallback: _roundedSystemFallbacks,
  );
}

TextStyle _roundedSubheadlineStyle({required Color color}) {
  return TextStyle(
    color: color,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontFamily: _roundedSystemFontFamily(),
    fontFamilyFallback: _roundedSystemFallbacks,
  );
}

String? _roundedSystemFontFamily() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return 'SF Pro Rounded';
    default:
      return null;
  }
}

const List<String> _roundedSystemFallbacks = [
  '.SF UI Rounded',
  'SF UI Rounded',
  'SF Pro Display',
];
