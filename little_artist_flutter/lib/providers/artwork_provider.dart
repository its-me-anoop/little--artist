import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/database.dart';
import 'database_provider.dart';

/// Provides a reactive stream of all artworks from the Drift database,
/// ordered by creation date descending.
final allArtworksProvider = StreamProvider<List<Artwork>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.artworkDao.watchAllArtworks();
});

/// Provides a reactive stream of artworks for a specific child,
/// ordered by creation date descending.
final artworksByChildProvider =
    StreamProvider.family<List<Artwork>, int>((ref, childId) {
  final db = ref.watch(databaseProvider);
  return db.artworkDao.watchArtworksByChild(childId);
});

/// Provides the total number of artworks in the Drift database.
final artworkCountProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.artworkDao.getArtworkCount();
});

/// Provides a reactive stream of favorited artworks from the Drift database,
/// ordered by creation date descending.
final favoriteArtworksProvider = StreamProvider<List<Artwork>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.artworkDao.getFavoriteArtworks();
});
