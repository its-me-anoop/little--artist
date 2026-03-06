import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashView(),
    ),
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
      ],
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchView(),
    ),
  ],
);

// ---------------------------------------------------------------------------
// MARK: - Scaffold with NavigationBar
// ---------------------------------------------------------------------------

class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Milestones',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MARK: - App
// ---------------------------------------------------------------------------

class LittleArtistApp extends StatelessWidget {
  const LittleArtistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Little Artist',
      debugShowCheckedModeBanner: false,
      theme: Brand.lightTheme,
      darkTheme: Brand.darkTheme,
      routerConfig: _router,
    );
  }
}
