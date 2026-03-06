import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/avatars/child_slider_view.dart';
import '../components/buttons/add_artwork_button.dart';
import '../components/cards/memory_card_view.dart';
import '../models/database.dart';
import '../providers/artwork_provider.dart';
import '../providers/children_provider.dart';
import '../utils/brand_tokens.dart';
import 'artwork/add_artwork_view.dart';
import 'artwork/artwork_detail_view.dart';
import 'artwork/artwork_gallery_view.dart';
import 'artwork/no_artwork_view.dart';

/// Main gallery tab view showing child filter, "On This Day" memories, and
/// an artwork grid.
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(allChildrenProvider);
    final artworksAsync = _selectedChildId != null
        ? ref.watch(artworksByChildProvider(_selectedChildId!))
        : ref.watch(allArtworksProvider);

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        title: Text(
          'Little Artist',
          style: Brand.title1Font.copyWith(color: Brand.charcoal),
        ),
        backgroundColor: Brand.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          // Main scrollable content
          artworksAsync.when(
            data: (artworks) => _buildContent(
              context,
              artworks: artworks,
              childrenAsync: childrenAsync,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Something went wrong',
                style: Brand.bodyFont.copyWith(color: Brand.warmGray),
              ),
            ),
          ),

          // FAB
          Positioned(
            right: Brand.screenPadding,
            bottom: Brand.screenPadding,
            child: AddArtworkButton(
              onPressed: () => _openAddArtwork(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required List<Artwork> artworks,
    required AsyncValue<List<Child>> childrenAsync,
  }) {
    final now = DateTime.now();
    final memories = artworks.where((a) {
      return a.createdAt.month == now.month &&
          a.createdAt.day == now.day &&
          a.createdAt.year != now.year;
    }).toList();

    return CustomScrollView(
      slivers: [
        // Child slider
        SliverToBoxAdapter(
          child: childrenAsync.when(
            data: (children) => children.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: Brand.sectionSpacing / 2,
                    ),
                    child: ChildSliderView(
                      children: children,
                      selectedChildId: _selectedChildId,
                      onChildSelected: (id) {
                        setState(() => _selectedChildId = id);
                      },
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, s) => const SizedBox.shrink(),
          ),
        ),

        // "On This Day" section
        if (memories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: Brand.screenPadding,
                bottom: 12,
              ),
              child: Text(
                'On This Day',
                style: Brand.title2Font.copyWith(color: Brand.charcoal),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Brand.screenPadding,
                ),
                itemCount: memories.length,
                separatorBuilder: (_, s) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final artwork = memories[index];
                  final yearsAgo = now.year - artwork.createdAt.year;
                  return SizedBox(
                    width: 280,
                    child: MemoryCardView(
                      artwork: artwork,
                      yearsAgo: yearsAgo,
                      onTap: () => _openArtworkDetail(context, artwork.id),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: Brand.sectionSpacing / 2),
          ),
        ],

        // Gallery section header
        if (artworks.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: Brand.screenPadding,
                bottom: 12,
              ),
              child: Text(
                'Gallery',
                style: Brand.title2Font.copyWith(color: Brand.charcoal),
              ),
            ),
          ),

        // Gallery grid or empty state
        if (artworks.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: NoArtworkView(),
          )
        else
          SliverToBoxAdapter(
            child: ArtworkGalleryView(
              artworks: artworks,
              onArtworkTap: (artwork) =>
                  _openArtworkDetail(context, artwork.id),
            ),
          ),

        // Bottom padding for FAB clearance
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  void _openAddArtwork(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddArtworkView(childId: _selectedChildId),
    );
  }

  void _openArtworkDetail(BuildContext context, int artworkId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArtworkDetailView(artworkId: artworkId),
      ),
    );
  }
}
