import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/database.dart';
import 'database_provider.dart';

/// Provides a reactive stream of all children from the Drift database,
/// ordered by creation date ascending.
final allChildrenProvider = StreamProvider<List<Child>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.childDao.watchAllChildren();
});

/// Provides the total number of children in the Drift database.
final childCountProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.childDao.getChildCount();
});
