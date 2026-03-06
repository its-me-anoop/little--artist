import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/cards/artwork_thumbnail_view.dart';
import '../components/chips/child_filter_chip_view.dart';
import '../models/database.dart';
import '../providers/children_provider.dart';
import '../providers/database_provider.dart';
import '../utils/brand_tokens.dart';

/// Full-text search across artworks with child, favorites, and tag filters.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _selectedChildId;
  bool _favoritesOnly = false;
  final Set<String> _selectedTags = {};

  Timer? _debounceTimer;
  List<Artwork> _searchResults = [];
  bool _isSearching = false;
  List<Tag> _allTags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    final db = ref.read(databaseProvider);
    final tags = await db.tagDao.getAllTags();
    if (mounted) {
      setState(() => _allTags = tags);
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim());
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (_query.isEmpty && _selectedChildId == null && !_favoritesOnly && _selectedTags.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final db = ref.read(databaseProvider);
    List<Artwork> results;

    if (_query.isNotEmpty) {
      results = await db.artworkDao.searchArtworks(_query);
    } else {
      // Fetch all artworks for filter-only queries
      results = await db.artworkDao.watchAllArtworks().first;
    }

    // Client-side filters
    if (_selectedChildId != null) {
      results = results.where((a) => a.childId == _selectedChildId).toList();
    }
    if (_favoritesOnly) {
      results = results.where((a) => a.isFavorited).toList();
    }
    if (_selectedTags.isNotEmpty) {
      final filteredResults = <Artwork>[];
      for (final artwork in results) {
        final artworkTags = await db.tagDao.getTagsForArtwork(artwork.id);
        final artworkTagNames = artworkTags.map((t) => t.name).toSet();
        if (_selectedTags.every((tag) => artworkTagNames.contains(tag))) {
          filteredResults.add(artwork);
        }
      }
      results = filteredResults;
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(allChildrenProvider);
    final hasActiveFilters =
        _query.isNotEmpty || _selectedChildId != null || _favoritesOnly || _selectedTags.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: Brand.title2Font),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Brand.screenPadding,
              vertical: 8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search artworks...',
                hintStyle: Brand.bodyFont.copyWith(color: Brand.warmGray),
                prefixIcon: const Icon(Icons.search, color: Brand.warmGray),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Brand.warmGray),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Brand.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Brand.radiusField),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Brand.fieldPadding,
                  vertical: Brand.fieldPadding,
                ),
              ),
              style: Brand.bodyFont.copyWith(color: Brand.charcoal),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Brand.screenPadding,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Favorites toggle
                  GestureDetector(
                    onTap: () {
                      setState(() => _favoritesOnly = !_favoritesOnly);
                      _performSearch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: _favoritesOnly ? Brand.primary : Brand.surface,
                        shape: StadiumBorder(
                          side: _favoritesOnly
                              ? BorderSide.none
                              : const BorderSide(color: Brand.softTan),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color:
                                _favoritesOnly ? Colors.white : Brand.dustyRose,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Favorites',
                            style: Brand.subheadlineFont.copyWith(
                              color: _favoritesOnly
                                  ? Colors.white
                                  : Brand.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Child filter chips
                  ...childrenAsync.when(
                    loading: () => <Widget>[],
                    error: (_, _) => <Widget>[],
                    data: (children) => children.map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChildFilterChipView(
                          label: child.name,
                          avatarColor: child.avatarColor,
                          isSelected: _selectedChildId == child.id,
                          onTap: () {
                            setState(() {
                              _selectedChildId = _selectedChildId == child.id
                                  ? null
                                  : child.id;
                            });
                            _performSearch();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Expanded(
            child: hasActiveFilters
                ? _buildResults()
                : _buildTagCloud(),
          ),
        ],
      ),
    );
  }

  // MARK: - Tag Cloud

  Widget _buildTagCloud() {
    if (_allTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Brand.warmGray.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Search your artwork',
              style: Brand.title2Font.copyWith(color: Brand.warmGray),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by title, caption, or tags',
              style: Brand.bodyFont.copyWith(color: Brand.warmGray),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Brand.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: Brand.headlineFont.copyWith(color: Brand.charcoal),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allTags.map((tag) {
              final isSelected = _selectedTags.contains(tag.name);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag.name);
                    } else {
                      _selectedTags.add(tag.name);
                    }
                  });
                  _performSearch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: isSelected ? Brand.primary : Brand.primaryTint,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    tag.name,
                    style: Brand.captionFont.copyWith(
                      color: isSelected ? Colors.white : Brand.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // MARK: - Results Grid

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Brand.warmGray.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No artworks found',
              style: Brand.title2Font.copyWith(color: Brand.warmGray),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or filter',
              style: Brand.bodyFont.copyWith(color: Brand.warmGray),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: Brand.screenPadding,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: Brand.thumbnailWidth / Brand.thumbnailHeight,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return ArtworkThumbnailView(artwork: _searchResults[index]);
      },
    );
  }
}
