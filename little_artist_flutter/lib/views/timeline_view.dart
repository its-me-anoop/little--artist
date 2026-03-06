import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../components/cards/timeline_entry_card_view.dart';
import '../components/chips/year_chip_view.dart';
import '../models/database.dart';
import '../providers/artwork_provider.dart';
import '../providers/children_provider.dart';
import '../utils/brand_tokens.dart';

/// Chronological feed of artworks grouped by month with a timeline spine,
/// year filter chips, and collapsible month sections.
class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({super.key});

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  int? _selectedYear;
  final Set<String> _collapsedMonths = {};

  @override
  Widget build(BuildContext context) {
    final artworksAsync = ref.watch(allArtworksProvider);
    final childrenAsync = ref.watch(allChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Timeline', style: Brand.title2Font),
      ),
      body: artworksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Something went wrong',
            style: Brand.bodyFont.copyWith(color: Brand.warmGray),
          ),
        ),
        data: (allArtworks) {
          if (allArtworks.isEmpty) {
            return _buildEmptyState();
          }

          final childMap = <int, Child>{};
          final children = childrenAsync.valueOrNull ?? [];
          for (final child in children) {
            childMap[child.id] = child;
          }

          // Extract available years
          final years = allArtworks
              .map((a) => a.createdAt.year)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          // Filter by selected year
          final filtered = _selectedYear == null
              ? allArtworks
              : allArtworks
                  .where((a) => a.createdAt.year == _selectedYear)
                  .toList();

          // Group by month
          final monthFormat = DateFormat('MMMM yyyy');
          final grouped = <String, List<Artwork>>{};
          for (final artwork in filtered) {
            final key = monthFormat.format(artwork.createdAt);
            grouped.putIfAbsent(key, () => []).add(artwork);
          }
          final monthKeys = grouped.keys.toList();

          return CustomScrollView(
            slivers: [
              // Year filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Brand.screenPadding,
                    vertical: 12,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        YearChipView(
                          year: 0, // "All" chip
                          isSelected: _selectedYear == null,
                          onTap: () => setState(() => _selectedYear = null),
                        ),
                        const SizedBox(width: 8),
                        ...years.map(
                          (year) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: YearChipView(
                              year: year,
                              isSelected: _selectedYear == year,
                              onTap: () => setState(() {
                                _selectedYear =
                                    _selectedYear == year ? null : year;
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Month groups
              for (final monthKey in monthKeys) ...[
                // Month header
                SliverToBoxAdapter(
                  child: _buildMonthHeader(monthKey),
                ),

                // Entries (if not collapsed)
                if (!_collapsedMonths.contains(monthKey))
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Brand.screenPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final artwork = grouped[monthKey]![index];
                          final childName =
                              artwork.childId != null
                                  ? childMap[artwork.childId]?.name
                                  : null;
                          final isLast =
                              index == grouped[monthKey]!.length - 1;

                          return _buildTimelineEntry(
                            artwork: artwork,
                            childName: childName,
                            isLast: isLast,
                          );
                        },
                        childCount: grouped[monthKey]!.length,
                      ),
                    ),
                  ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: Brand.sectionSpacing),
              ),
            ],
          );
        },
      ),
    );
  }

  // MARK: - Empty State

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 80,
            color: Brand.warmGray.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No artworks yet',
            style: Brand.title2Font.copyWith(color: Brand.warmGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Add artwork to see your timeline',
            style: Brand.bodyFont.copyWith(color: Brand.warmGray),
          ),
        ],
      ),
    );
  }

  // MARK: - Month Header

  Widget _buildMonthHeader(String monthKey) {
    final isCollapsed = _collapsedMonths.contains(monthKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isCollapsed) {
            _collapsedMonths.remove(monthKey);
          } else {
            _collapsedMonths.add(monthKey);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: Brand.screenPadding,
          right: Brand.screenPadding,
          top: Brand.sectionSpacing,
          bottom: 12,
        ),
        child: Row(
          children: [
            Text(
              monthKey,
              style: Brand.headlineFont.copyWith(color: Brand.charcoal),
            ),
            const SizedBox(width: 8),
            Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              size: 20,
              color: Brand.warmGray,
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Timeline Entry

  Widget _buildTimelineEntry({
    required Artwork artwork,
    String? childName,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Brand.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                // Vertical line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Brand.softTan,
                    ),
                  ),
                if (isLast) const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TimelineEntryCardView(
                artwork: artwork,
                childName: childName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
