import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/database.dart';

/// Riverpod provider for the app-wide Drift database.
///
/// This provider must be overridden at app startup with the result of
/// [createDatabase] so that the correct application-documents path is used.
///
/// Example (in main.dart):
/// ```dart
/// final db = await createDatabase();
/// runApp(
///   ProviderScope(
///     overrides: [databaseProvider.overrideWithValue(db)],
///     child: const MyApp(),
///   ),
/// );
/// ```
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden with a concrete AppDatabase instance '
    'at app startup. Call createDatabase() and pass the result via '
    'databaseProvider.overrideWithValue(db).',
  );
});

/// Creates and returns the [AppDatabase] backed by a SQLite file in the
/// application documents directory.
Future<AppDatabase> createDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'little_artist.db'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}
