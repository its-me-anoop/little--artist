import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../components/chips/tag_chip_view.dart';
import '../../models/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/haptic_service.dart';
import '../../utils/brand_tokens.dart';
import 'add_artwork_view.dart';

/// Full-screen artwork detail view with pinch-to-zoom, metadata, and actions.
class ArtworkDetailView extends ConsumerStatefulWidget {
  final int artworkId;

  const ArtworkDetailView({
    super.key,
    required this.artworkId,
  });

  @override
  ConsumerState<ArtworkDetailView> createState() => _ArtworkDetailViewState();
}

class _ArtworkDetailViewState extends ConsumerState<ArtworkDetailView> {
  Artwork? _artwork;
  Child? _child;
  List<Tag> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final artwork = await db.artworkDao.getArtworkById(widget.artworkId);
    if (artwork == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    Child? child;
    if (artwork.childId != null) {
      child = await db.childDao.getChildById(artwork.childId!);
    }

    final tags = await db.tagDao.getTagsForArtwork(artwork.id);

    if (mounted) {
      setState(() {
        _artwork = artwork;
        _child = child;
        _tags = tags;
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleFavorite() async {
    if (_artwork == null) return;
    final repo = ref.read(firestoreRepositoryProvider);
    await repo.updateArtwork(
      _artwork!,
      isFavorited: !_artwork!.isFavorited,
    );
    HapticService.selection();
    _loadData();
  }

  Future<void> _shareArtwork() async {
    if (_artwork?.imageData == null) return;
    await Share.shareXFiles(
      [
        XFile.fromData(
          _artwork!.imageData!,
          mimeType: 'image/jpeg',
          name: '${_artwork!.title}.jpg',
        ),
      ],
      text: _artwork!.title,
    );
  }

  void _editArtwork() {
    if (_artwork == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddArtworkView(
        existingArtwork: _artwork,
        childId: _artwork!.childId,
      ),
    ).then((_) => _loadData());
  }

  Future<void> _deleteArtwork() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Artwork'),
        content:
            const Text('This artwork will be permanently deleted. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Brand.dustyRose),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || _artwork == null) return;

    final repo = ref.read(firestoreRepositoryProvider);
    await repo.deleteArtwork(_artwork!.id);
    HapticService.warning();
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // MARK: - Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Brand.cream,
        appBar: AppBar(backgroundColor: Brand.cream),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_artwork == null) {
      return Scaffold(
        backgroundColor: Brand.cream,
        appBar: AppBar(backgroundColor: Brand.cream),
        body: Center(
          child: Text(
            'Artwork not found',
            style: Brand.bodyFont.copyWith(color: Brand.warmGray),
          ),
        ),
      );
    }

    final artwork = _artwork!;
    final imageBytes = artwork.imageData;
    final dateText = DateFormat.yMMMMd().format(artwork.createdAt);

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        backgroundColor: Brand.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              artwork.isFavorited ? Icons.favorite : Icons.favorite_border,
              color: artwork.isFavorited ? Brand.dustyRose : Brand.charcoal,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareArtwork,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editArtwork,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Brand.dustyRose),
            onPressed: _deleteArtwork,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-width image with pinch-to-zoom
            if (imageBytes != null)
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: SizedBox(
                  width: double.infinity,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                color: Brand.surface,
                child: const Center(
                  child: Icon(
                    Icons.palette_outlined,
                    size: 64,
                    color: Brand.warmGray,
                  ),
                ),
              ),

            // Metadata card
            Padding(
              padding: const EdgeInsets.all(Brand.screenPadding),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Brand.buttonPadding),
                decoration: BoxDecoration(
                  color: Brand.surface,
                  borderRadius: BorderRadius.circular(Brand.radiusCard),
                  boxShadow: Brand.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      artwork.title,
                      style:
                          Brand.title2Font.copyWith(color: Brand.charcoal),
                    ),

                    // Caption
                    if (artwork.caption.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        artwork.caption,
                        style:
                            Brand.bodyFont.copyWith(color: Brand.warmGray),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Date
                    Text(
                      dateText,
                      style:
                          Brand.captionFont.copyWith(color: Brand.warmGray),
                    ),

                    // Child name badge
                    if (_child != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse('FF${_child!.avatarColor}',
                                radix: 16),
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _child!.name,
                          style: Brand.captionFont.copyWith(
                            color: Color(
                              int.parse('FF${_child!.avatarColor}',
                                  radix: 16),
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    // Tags
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map((tag) => TagChipView(name: tag.name))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
