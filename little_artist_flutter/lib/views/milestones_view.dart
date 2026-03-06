import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/cards/achievement_badge_view.dart';
import '../components/cards/stat_card_view.dart';
import '../providers/artwork_provider.dart';
import '../providers/children_provider.dart';
import '../utils/brand_tokens.dart';

/// Stats and achievements overview showing artwork counts, child counts,
/// and unlockable achievement badges.
class MilestonesView extends ConsumerWidget {
  const MilestonesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworksAsync = ref.watch(allArtworksProvider);
    final childrenAsync = ref.watch(allChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Milestones', style: Brand.title2Font),
      ),
      body: artworksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Something went wrong',
            style: Brand.bodyFont.copyWith(color: Brand.warmGray),
          ),
        ),
        data: (artworks) {
          final children = childrenAsync.valueOrNull ?? [];
          final totalArtworks = artworks.length;
          final totalChildren = children.length;
          final favorites = artworks.where((a) => a.isFavorited).length;

          final now = DateTime.now();
          final thisMonth = artworks.where((a) =>
              a.createdAt.year == now.year &&
              a.createdAt.month == now.month).length;

          final hasSharedChild = children.any((c) => c.isShared);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Brand.screenPadding,
              vertical: Brand.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCardView(
                      icon: Icons.palette,
                      value: '$totalArtworks',
                      label: 'Total Artworks',
                      iconColor: Brand.primary,
                    ),
                    StatCardView(
                      icon: Icons.people,
                      value: '$totalChildren',
                      label: 'Total Children',
                      iconColor: Brand.sage,
                    ),
                    StatCardView(
                      icon: Icons.favorite,
                      value: '$favorites',
                      label: 'Favorites',
                      iconColor: Brand.dustyRose,
                    ),
                    StatCardView(
                      icon: Icons.calendar_month,
                      value: '$thisMonth',
                      label: 'This Month',
                      iconColor: Brand.sky,
                    ),
                  ],
                ),

                const SizedBox(height: Brand.sectionSpacing),

                // Achievements section
                Text(
                  'Achievements',
                  style: Brand.title2Font.copyWith(color: Brand.charcoal),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    AchievementBadgeView(
                      icon: Icons.brush,
                      title: 'First Artwork',
                      description: '1 artwork',
                      isUnlocked: totalArtworks >= 1,
                      color: Brand.primary,
                    ),
                    AchievementBadgeView(
                      icon: Icons.auto_awesome,
                      title: 'Getting Started',
                      description: '5 artworks',
                      isUnlocked: totalArtworks >= 5,
                      color: Brand.sage,
                    ),
                    AchievementBadgeView(
                      icon: Icons.star,
                      title: 'Prolific Artist',
                      description: '25 artworks',
                      isUnlocked: totalArtworks >= 25,
                      color: Brand.sky,
                    ),
                    AchievementBadgeView(
                      icon: Icons.collections,
                      title: 'Art Collection',
                      description: '50 artworks',
                      isUnlocked: totalArtworks >= 50,
                      color: Brand.lavender,
                    ),
                    AchievementBadgeView(
                      icon: Icons.workspace_premium,
                      title: 'Master Artist',
                      description: '100 artworks',
                      isUnlocked: totalArtworks >= 100,
                      color: Brand.primary,
                    ),
                    AchievementBadgeView(
                      icon: Icons.share,
                      title: 'First Share',
                      description: 'Shared a child',
                      isUnlocked: hasSharedChild,
                      color: Brand.sage,
                    ),
                  ],
                ),

                const SizedBox(height: Brand.sectionSpacing),
              ],
            ),
          );
        },
      ),
    );
  }
}
