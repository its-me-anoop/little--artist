import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'utils/brand_tokens.dart';
import 'views/home_view.dart';
import 'views/timeline_view.dart';
import 'views/milestones_view.dart';
import 'views/settings_view.dart';
import 'views/search_view.dart';
import 'views/splash_view.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/artwork/artwork_detail_view.dart';
import 'views/artwork/add_artwork_view.dart';
import 'views/children/add_child_view.dart';
import 'views/children/edit_child_view.dart';

// ---------------------------------------------------------------------------
// MARK: - Router
// ---------------------------------------------------------------------------

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashView()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingView(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/gallery',
              builder: (context, state) => const HomeView(),
              routes: [
                GoRoute(
                  path: 'artwork/add',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final childId = state.uri.queryParameters['childId'];
                    return MaterialPage(
                      fullscreenDialog: true,
                      child: AddArtworkView(
                        childId: childId != null ? int.tryParse(childId) : null,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'artwork/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return ArtworkDetailView(artworkId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/timeline',
              builder: (context, state) => const TimelineView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/milestones',
              builder: (context, state) => const MilestonesView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsView(),
              routes: [
                GoRoute(
                  path: 'children/add',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) => const MaterialPage(
                    fullscreenDialog: true,
                    child: AddChildView(),
                  ),
                ),
                GoRoute(
                  path: 'children/:id/edit',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return EditChildView(childId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchView(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// MARK: - Scaffold with NavigationBar
// ---------------------------------------------------------------------------

class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _OnboardingTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _OnboardingTabBar extends StatelessWidget {
  const _OnboardingTabBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final accentColor = _tabAccent(currentIndex);
    final secondaryAccent = _tabAccent((currentIndex + 2) % _tabCount);

    return SizedBox(
      height: bottomInset + 112,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 28,
            bottom: bottomInset + 36,
            child: _TabBarOrb(
              size: 48,
              color: accentColor.withValues(alpha: 0.24),
              sigma: 24,
            ),
          ),
          Positioned(
            right: 34,
            bottom: bottomInset + 14,
            child: _TabBarOrb(
              size: 34,
              color: secondaryAccent.withValues(alpha: 0.18),
              sigma: 18,
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: bottomInset > 0 ? 10 : 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.96),
                    Brand.surface.withValues(alpha: 0.98),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.18),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Brand.charcoal.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      height: 24,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.42),
                                Colors.white.withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(_tabCount, (index) {
                          final active = index == currentIndex;
                          return Expanded(
                            child: _OnboardingTabButton(
                              index: index,
                              label: _tabLabel(index),
                              icon: _tabIcon(index, active),
                              accentColor: _tabAccent(index),
                              active: active,
                              onTap: () => onTap(index),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingTabButton extends StatelessWidget {
  const _OnboardingTabButton({
    required this.index,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.active,
    required this.onTap,
  });

  final int index;
  final String label;
  final Widget icon;
  final Color accentColor;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final angle = active ? ((index.isEven ? -0.85 : 0.7) * (math.pi / 180)) : 0.0;
    final foregroundColor = active ? Colors.white : Brand.warmGray;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Transform.rotate(
          angle: angle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.92),
                        accentColor,
                      ],
                    )
                  : null,
              color: active ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(active ? 22 : 18),
              border: active
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 2.4,
                    )
                  : null,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.34),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(active ? 22 : 18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconTheme(
                        data: IconThemeData(color: foregroundColor, size: 20),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: KeyedSubtree(
                            key: ValueKey('$label-$active'),
                            child: icon,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        style: _roundedTabLabelStyle(
                          color: foregroundColor,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const int _tabCount = 5;

String _tabLabel(int index) {
  switch (index) {
    case 0:
      return 'Gallery';
    case 1:
      return 'Timeline';
    case 2:
      return 'Milestones';
    case 3:
      return 'Settings';
    case 4:
      return 'Search';
  }
  throw RangeError.index(index, List<int>.generate(_tabCount, (i) => i));
}

Color _tabAccent(int index) {
  switch (index) {
    case 0:
      return Brand.primary;
    case 1:
      return Brand.sage;
    case 2:
      return Brand.sky;
    case 3:
      return Brand.lavender;
    case 4:
      return Brand.dustyRose;
  }
  throw RangeError.index(index, List<int>.generate(_tabCount, (i) => i));
}

Widget _tabIcon(int index, bool active) {
  switch (index) {
    case 0:
      return Icon(
        active
            ? CupertinoIcons.photo_fill_on_rectangle_fill
            : CupertinoIcons.photo_on_rectangle,
      );
    case 1:
      return _TimelineTabIcon(active: active);
    case 2:
      return Icon(active ? CupertinoIcons.star_fill : CupertinoIcons.star);
    case 3:
      return Icon(active ? CupertinoIcons.gear_solid : CupertinoIcons.gear);
    case 4:
      return const Icon(CupertinoIcons.search);
  }
  throw RangeError.index(index, List<int>.generate(_tabCount, (i) => i));
}

class _TabBarOrb extends StatelessWidget {
  const _TabBarOrb({
    required this.size,
    required this.color,
    required this.sigma,
  });

  final double size;
  final Color color;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _TimelineTabIcon extends StatelessWidget {
  const _TimelineTabIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            active ? CupertinoIcons.time_solid : CupertinoIcons.time,
            size: 22,
          ),
          Positioned(
            top: -1,
            right: -2,
            child: Transform.rotate(
              angle: 1.57,
              child: Icon(
                active
                    ? CupertinoIcons.arrow_counterclockwise_circle_fill
                    : CupertinoIcons.arrow_counterclockwise_circle,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _roundedTabLabelStyle({
  required Color color,
  required FontWeight fontWeight,
}) {
  return TextStyle(
    color: color,
    fontSize: 11.5,
    fontWeight: fontWeight,
    fontFamily: _roundedSystemFontFamily(),
    fontFamilyFallback: _roundedSystemFallbacks,
    height: 1.0,
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

// ---------------------------------------------------------------------------
// MARK: - App
// ---------------------------------------------------------------------------

class LittleArtistApp extends ConsumerStatefulWidget {
  const LittleArtistApp({super.key});

  @override
  ConsumerState<LittleArtistApp> createState() => _LittleArtistAppState();
}

class _LittleArtistAppState extends ConsumerState<LittleArtistApp> {
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(firebaseAuthServiceProvider).signInAnonymously();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) async {
        final syncService = ref.read(syncServiceProvider);
        final repository = ref.read(firestoreRepositoryProvider);

        if (user == null) {
          _activeUserId = null;
          await syncService.stop();
          return;
        }

        if (_activeUserId == user.uid && syncService.isListening) {
          return;
        }

        if (_activeUserId != null && _activeUserId != user.uid) {
          await syncService.stop();
        }

        _activeUserId = user.uid;
        syncService.start();
        await repository.syncUserPreferencesToFirestore();
        unawaited(repository.uploadAllLocalData());
      });
    });

    return MaterialApp.router(
      title: 'Little Artist',
      debugShowCheckedModeBanner: false,
      theme: Brand.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
