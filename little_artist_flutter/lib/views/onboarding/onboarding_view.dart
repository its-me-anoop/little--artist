import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../utils/brand_tokens.dart';
import 'animated_cards_view.dart';

/// Multi-page onboarding flow with animated card backgrounds.
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      headline: 'Welcome to\nLittle Artist',
      description: 'Capture and celebrate your child\'s creativity',
    ),
    _OnboardingPageData(
      headline: 'Organize &\nDiscover',
      description: 'Build a beautiful gallery of artwork over time',
    ),
    _OnboardingPageData(
      headline: 'Share &\nRemember',
      description: 'Share with family and relive precious moments',
    ),
    _OnboardingPageData(
      headline: 'Get Started',
      description: 'Sign in to sync across devices, or jump right in',
    ),
  ];

  // ---------------------------------------------------------------------------
  // MARK: - Actions
  // ---------------------------------------------------------------------------

  void _goToNextPage() {
    HapticService.selection();
    _pageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _signInWithApple() async {
    final authService = ref.read(firebaseAuthServiceProvider);
    final success = await authService.signInWithApple();
    if (success && mounted) {
      await _completeOnboarding();
    }
  }

  Future<void> _continueWithoutAccount() async {
    final authService = ref.read(firebaseAuthServiceProvider);
    await authService.signInAnonymously();
    if (mounted) {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    if (mounted) {
      context.go('/gallery');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Build
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(firebaseAuthServiceProvider);

    return Scaffold(
      backgroundColor: Brand.adaptiveCream(context),
      body: SafeArea(
        child: Column(
          children: [
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Brand.screenPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated cards
                        AnimatedCardsView(pageIndex: index),
                        const SizedBox(height: Brand.sectionSpacing),

                        // Headline
                        Text(
                          page.headline,
                          textAlign: TextAlign.center,
                          style: Brand.displayFont.copyWith(
                            color: Brand.adaptiveCharcoal(context),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: Brand.bodyFont.copyWith(
                            color: Brand.adaptiveWarmGray(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Brand.screenPadding,
                0,
                Brand.screenPadding,
                Brand.screenPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Brand.primary
                              : Brand.adaptiveSoftTan(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: Brand.sectionSpacing),

                  // Action buttons
                  if (_currentPage < 3) ...[
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _goToNextPage,
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Brand.radiusButton),
                          ),
                          textStyle: Brand.headlineFont,
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ] else ...[
                    // Sign in with Apple
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed:
                            authService.isAuthenticating
                                ? null
                                : _signInWithApple,
                        icon: const Icon(Icons.apple, size: 24),
                        label: Text(
                          authService.isAuthenticating
                              ? 'Signing in...'
                              : 'Sign in with Apple',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.adaptiveCharcoal(context),
                          foregroundColor: Brand.adaptiveCream(context),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Brand.radiusButton),
                          ),
                          textStyle: Brand.headlineFont,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Continue without account
                    TextButton(
                      onPressed:
                          authService.isAuthenticating
                              ? null
                              : _continueWithoutAccount,
                      style: TextButton.styleFrom(
                        foregroundColor: Brand.adaptiveWarmGray(context),
                        textStyle: Brand.subheadlineFont,
                      ),
                      child: const Text('Continue without account'),
                    ),
                  ],

                  // Error message
                  if (authService.authError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      authService.authError!,
                      textAlign: TextAlign.center,
                      style: Brand.captionFont.copyWith(
                        color: Brand.dustyRose,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MARK: - Page Data
// ---------------------------------------------------------------------------

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.headline,
    required this.description,
  });

  final String headline;
  final String description;
}
