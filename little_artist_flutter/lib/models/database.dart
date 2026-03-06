import 'package:drift/drift.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

@DataClassName('Child')
class Children extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get avatarColor =>
      text().withDefault(const Constant('F2784B'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  BlobColumn get avatarImageData => blob().nullable()();
  TextColumn get firestoreId => text().nullable()();
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();
  TextColumn get ownerUserId => text().nullable()();
}

class Artworks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get caption => text().withDefault(const Constant(''))();
  BlobColumn get imageData => blob().nullable()();
  BlobColumn get thumbnailData => blob().nullable()();
  BlobColumn get voiceNoteData => blob().nullable()();
  BoolColumn get isFavorited =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get childId =>
      integer().nullable().references(Children, #id, onDelete: KeyAction.cascade)();
  TextColumn get firestoreId => text().nullable()();
  TextColumn get imageURL => text().nullable()();
  TextColumn get voiceNoteURL => text().nullable()();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class ArtworkTags extends Table {
  IntColumn get artworkId =>
      integer().references(Artworks, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {artworkId, tagId};
}

// ---------------------------------------------------------------------------
// DAOs
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [Children])
class ChildDao extends DatabaseAccessor<AppDatabase> with _$ChildDaoMixin {
  ChildDao(super.db);

  Stream<List<Child>> watchAllChildren() {
    return (select(children)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<Child?> getChildById(int id) {
    return (select(children)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Child?> getChildByFirestoreId(String firestoreId) {
    return (select(children)..where((t) => t.firestoreId.equals(firestoreId)))
        .getSingleOrNull();
  }

  Future<int> insertChild(ChildrenCompanion child) {
    return into(children).insert(child);
  }

  Future<bool> updateChild(Child child) {
    return update(children).replace(child);
  }

  Future<int> deleteChild(int id) {
    return (delete(children)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getChildCount() async {
    final count = countAll();
    final query = selectOnly(children)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count)!;
  }
}

@DriftAccessor(tables: [Artworks])
class ArtworkDao extends DatabaseAccessor<AppDatabase>
    with _$ArtworkDaoMixin {
  ArtworkDao(super.db);

  Stream<List<Artwork>> watchArtworksByChild(int childId) {
    return (select(artworks)
          ..where((t) => t.childId.equals(childId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Artwork>> watchAllArtworks() {
    return (select(artworks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<Artwork?> getArtworkById(int id) {
    return (select(artworks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Artwork?> getArtworkByFirestoreId(String firestoreId) {
    return (select(artworks)
          ..where((t) => t.firestoreId.equals(firestoreId)))
        .getSingleOrNull();
  }

  Future<int> insertArtwork(ArtworksCompanion artwork) {
    return into(artworks).insert(artwork);
  }

  Future<bool> updateArtwork(Artwork artwork) {
    return update(artworks).replace(artwork);
  }

  Future<int> deleteArtwork(int id) {
    return (delete(artworks)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getArtworkCount() async {
    final count = countAll();
    final query = selectOnly(artworks)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count)!;
  }

  Future<int> getArtworkCountForChild(int childId) async {
    final count = countAll();
    final query = selectOnly(artworks)
      ..addColumns([count])
      ..where(artworks.childId.equals(childId));
    final result = await query.getSingle();
    return result.read(count)!;
  }

  Future<List<Artwork>> searchArtworks(String query) {
    final pattern = '%$query%';
    return (select(artworks)
          ..where(
              (t) => t.title.like(pattern) | t.caption.like(pattern))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Stream<List<Artwork>> getFavoriteArtworks() {
    return (select(artworks)
          ..where((t) => t.isFavorited.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}

@DriftAccessor(tables: [Tags, ArtworkTags, Artworks])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Future<List<Tag>> getAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<int> getOrCreateTag(String name) async {
    final existing = await (select(tags)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return into(tags).insert(TagsCompanion.insert(name: name));
  }

  Future<void> addTagToArtwork(int artworkId, int tagId) {
    return into(artworkTags).insert(
      ArtworkTagsCompanion.insert(artworkId: artworkId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeTagFromArtwork(int artworkId, int tagId) {
    return (delete(artworkTags)
          ..where(
              (t) => t.artworkId.equals(artworkId) & t.tagId.equals(tagId)))
        .go()
        .then((_) {});
  }

  Future<List<Tag>> getTagsForArtwork(int artworkId) {
    final query = select(tags).join([
      innerJoin(artworkTags, artworkTags.tagId.equalsExp(tags.id)),
    ])
      ..where(artworkTags.artworkId.equals(artworkId))
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.map((row) => row.readTable(tags)).get();
  }

  Stream<List<Artwork>> getArtworksByTag(int tagId) {
    final query = select(artworks).join([
      innerJoin(artworkTags, artworkTags.artworkId.equalsExp(artworks.id)),
    ])
      ..where(artworkTags.tagId.equals(tagId))
      ..orderBy([OrderingTerm.desc(artworks.createdAt)]);
    return query.map((row) => row.readTable(artworks)).watch();
  }
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [Children, Artworks, Tags, ArtworkTags],
  daos: [ChildDao, ArtworkDao, TagDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
