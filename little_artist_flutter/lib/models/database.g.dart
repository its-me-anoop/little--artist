// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
mixin _$ChildDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChildrenTable get children => attachedDatabase.children;
}
mixin _$ArtworkDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChildrenTable get children => attachedDatabase.children;
  $ArtworksTable get artworks => attachedDatabase.artworks;
}
mixin _$TagDaoMixin on DatabaseAccessor<AppDatabase> {
  $TagsTable get tags => attachedDatabase.tags;
  $ChildrenTable get children => attachedDatabase.children;
  $ArtworksTable get artworks => attachedDatabase.artworks;
  $ArtworkTagsTable get artworkTags => attachedDatabase.artworkTags;
}

class $ChildrenTable extends Children with TableInfo<$ChildrenTable, Child> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildrenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avatarColorMeta = const VerificationMeta(
    'avatarColor',
  );
  @override
  late final GeneratedColumn<String> avatarColor = GeneratedColumn<String>(
    'avatar_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('F2784B'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _avatarImageDataMeta = const VerificationMeta(
    'avatarImageData',
  );
  @override
  late final GeneratedColumn<Uint8List> avatarImageData =
      GeneratedColumn<Uint8List>(
        'avatar_image_data',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSharedMeta = const VerificationMeta(
    'isShared',
  );
  @override
  late final GeneratedColumn<bool> isShared = GeneratedColumn<bool>(
    'is_shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    avatarColor,
    createdAt,
    avatarImageData,
    firestoreId,
    isShared,
    ownerUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'children';
  @override
  VerificationContext validateIntegrity(
    Insertable<Child> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
        _avatarColorMeta,
        avatarColor.isAcceptableOrUnknown(
          data['avatar_color']!,
          _avatarColorMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('avatar_image_data')) {
      context.handle(
        _avatarImageDataMeta,
        avatarImageData.isAcceptableOrUnknown(
          data['avatar_image_data']!,
          _avatarImageDataMeta,
        ),
      );
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('is_shared')) {
      context.handle(
        _isSharedMeta,
        isShared.isAcceptableOrUnknown(data['is_shared']!, _isSharedMeta),
      );
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Child map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Child(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      avatarImageData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}avatar_image_data'],
      ),
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      isShared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shared'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
    );
  }

  @override
  $ChildrenTable createAlias(String alias) {
    return $ChildrenTable(attachedDatabase, alias);
  }
}

class Child extends DataClass implements Insertable<Child> {
  final int id;
  final String name;
  final String avatarColor;
  final DateTime createdAt;
  final Uint8List? avatarImageData;
  final String? firestoreId;
  final bool isShared;
  final String? ownerUserId;
  const Child({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.createdAt,
    this.avatarImageData,
    this.firestoreId,
    required this.isShared,
    this.ownerUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['avatar_color'] = Variable<String>(avatarColor);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || avatarImageData != null) {
      map['avatar_image_data'] = Variable<Uint8List>(avatarImageData);
    }
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    map['is_shared'] = Variable<bool>(isShared);
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    return map;
  }

  ChildrenCompanion toCompanion(bool nullToAbsent) {
    return ChildrenCompanion(
      id: Value(id),
      name: Value(name),
      avatarColor: Value(avatarColor),
      createdAt: Value(createdAt),
      avatarImageData: avatarImageData == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarImageData),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      isShared: Value(isShared),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
    );
  }

  factory Child.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Child(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarColor: serializer.fromJson<String>(json['avatarColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      avatarImageData: serializer.fromJson<Uint8List?>(json['avatarImageData']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      isShared: serializer.fromJson<bool>(json['isShared']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'avatarColor': serializer.toJson<String>(avatarColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'avatarImageData': serializer.toJson<Uint8List?>(avatarImageData),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'isShared': serializer.toJson<bool>(isShared),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
    };
  }

  Child copyWith({
    int? id,
    String? name,
    String? avatarColor,
    DateTime? createdAt,
    Value<Uint8List?> avatarImageData = const Value.absent(),
    Value<String?> firestoreId = const Value.absent(),
    bool? isShared,
    Value<String?> ownerUserId = const Value.absent(),
  }) => Child(
    id: id ?? this.id,
    name: name ?? this.name,
    avatarColor: avatarColor ?? this.avatarColor,
    createdAt: createdAt ?? this.createdAt,
    avatarImageData: avatarImageData.present
        ? avatarImageData.value
        : this.avatarImageData,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    isShared: isShared ?? this.isShared,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
  );
  Child copyWithCompanion(ChildrenCompanion data) {
    return Child(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarColor: data.avatarColor.present
          ? data.avatarColor.value
          : this.avatarColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      avatarImageData: data.avatarImageData.present
          ? data.avatarImageData.value
          : this.avatarImageData,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      isShared: data.isShared.present ? data.isShared.value : this.isShared,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Child(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarImageData: $avatarImageData, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('isShared: $isShared, ')
          ..write('ownerUserId: $ownerUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    avatarColor,
    createdAt,
    $driftBlobEquality.hash(avatarImageData),
    firestoreId,
    isShared,
    ownerUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Child &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarColor == this.avatarColor &&
          other.createdAt == this.createdAt &&
          $driftBlobEquality.equals(
            other.avatarImageData,
            this.avatarImageData,
          ) &&
          other.firestoreId == this.firestoreId &&
          other.isShared == this.isShared &&
          other.ownerUserId == this.ownerUserId);
}

class ChildrenCompanion extends UpdateCompanion<Child> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> avatarColor;
  final Value<DateTime> createdAt;
  final Value<Uint8List?> avatarImageData;
  final Value<String?> firestoreId;
  final Value<bool> isShared;
  final Value<String?> ownerUserId;
  const ChildrenCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarImageData = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.isShared = const Value.absent(),
    this.ownerUserId = const Value.absent(),
  });
  ChildrenCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarImageData = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.isShared = const Value.absent(),
    this.ownerUserId = const Value.absent(),
  });
  static Insertable<Child> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? avatarColor,
    Expression<DateTime>? createdAt,
    Expression<Uint8List>? avatarImageData,
    Expression<String>? firestoreId,
    Expression<bool>? isShared,
    Expression<String>? ownerUserId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (createdAt != null) 'created_at': createdAt,
      if (avatarImageData != null) 'avatar_image_data': avatarImageData,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (isShared != null) 'is_shared': isShared,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
    });
  }

  ChildrenCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? avatarColor,
    Value<DateTime>? createdAt,
    Value<Uint8List?>? avatarImageData,
    Value<String?>? firestoreId,
    Value<bool>? isShared,
    Value<String?>? ownerUserId,
  }) {
    return ChildrenCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
      createdAt: createdAt ?? this.createdAt,
      avatarImageData: avatarImageData ?? this.avatarImageData,
      firestoreId: firestoreId ?? this.firestoreId,
      isShared: isShared ?? this.isShared,
      ownerUserId: ownerUserId ?? this.ownerUserId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<String>(avatarColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (avatarImageData.present) {
      map['avatar_image_data'] = Variable<Uint8List>(avatarImageData.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (isShared.present) {
      map['is_shared'] = Variable<bool>(isShared.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildrenCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarImageData: $avatarImageData, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('isShared: $isShared, ')
          ..write('ownerUserId: $ownerUserId')
          ..write(')'))
        .toString();
  }
}

class $ArtworksTable extends Artworks with TableInfo<$ArtworksTable, Artwork> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtworksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageDataMeta = const VerificationMeta(
    'imageData',
  );
  @override
  late final GeneratedColumn<Uint8List> imageData = GeneratedColumn<Uint8List>(
    'image_data',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailDataMeta = const VerificationMeta(
    'thumbnailData',
  );
  @override
  late final GeneratedColumn<Uint8List> thumbnailData =
      GeneratedColumn<Uint8List>(
        'thumbnail_data',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _voiceNoteDataMeta = const VerificationMeta(
    'voiceNoteData',
  );
  @override
  late final GeneratedColumn<Uint8List> voiceNoteData =
      GeneratedColumn<Uint8List>(
        'voice_note_data',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isFavoritedMeta = const VerificationMeta(
    'isFavorited',
  );
  @override
  late final GeneratedColumn<bool> isFavorited = GeneratedColumn<bool>(
    'is_favorited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<int> childId = GeneratedColumn<int>(
    'child_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageURLMeta = const VerificationMeta(
    'imageURL',
  );
  @override
  late final GeneratedColumn<String> imageURL = GeneratedColumn<String>(
    'image_u_r_l',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voiceNoteURLMeta = const VerificationMeta(
    'voiceNoteURL',
  );
  @override
  late final GeneratedColumn<String> voiceNoteURL = GeneratedColumn<String>(
    'voice_note_u_r_l',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    caption,
    imageData,
    thumbnailData,
    voiceNoteData,
    isFavorited,
    createdAt,
    childId,
    firestoreId,
    imageURL,
    voiceNoteURL,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artworks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Artwork> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('image_data')) {
      context.handle(
        _imageDataMeta,
        imageData.isAcceptableOrUnknown(data['image_data']!, _imageDataMeta),
      );
    }
    if (data.containsKey('thumbnail_data')) {
      context.handle(
        _thumbnailDataMeta,
        thumbnailData.isAcceptableOrUnknown(
          data['thumbnail_data']!,
          _thumbnailDataMeta,
        ),
      );
    }
    if (data.containsKey('voice_note_data')) {
      context.handle(
        _voiceNoteDataMeta,
        voiceNoteData.isAcceptableOrUnknown(
          data['voice_note_data']!,
          _voiceNoteDataMeta,
        ),
      );
    }
    if (data.containsKey('is_favorited')) {
      context.handle(
        _isFavoritedMeta,
        isFavorited.isAcceptableOrUnknown(
          data['is_favorited']!,
          _isFavoritedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('image_u_r_l')) {
      context.handle(
        _imageURLMeta,
        imageURL.isAcceptableOrUnknown(data['image_u_r_l']!, _imageURLMeta),
      );
    }
    if (data.containsKey('voice_note_u_r_l')) {
      context.handle(
        _voiceNoteURLMeta,
        voiceNoteURL.isAcceptableOrUnknown(
          data['voice_note_u_r_l']!,
          _voiceNoteURLMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Artwork map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Artwork(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      )!,
      imageData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}image_data'],
      ),
      thumbnailData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}thumbnail_data'],
      ),
      voiceNoteData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}voice_note_data'],
      ),
      isFavorited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorited'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}child_id'],
      ),
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      imageURL: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_u_r_l'],
      ),
      voiceNoteURL: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_note_u_r_l'],
      ),
    );
  }

  @override
  $ArtworksTable createAlias(String alias) {
    return $ArtworksTable(attachedDatabase, alias);
  }
}

class Artwork extends DataClass implements Insertable<Artwork> {
  final int id;
  final String title;
  final String caption;
  final Uint8List? imageData;
  final Uint8List? thumbnailData;
  final Uint8List? voiceNoteData;
  final bool isFavorited;
  final DateTime createdAt;
  final int? childId;
  final String? firestoreId;
  final String? imageURL;
  final String? voiceNoteURL;
  const Artwork({
    required this.id,
    required this.title,
    required this.caption,
    this.imageData,
    this.thumbnailData,
    this.voiceNoteData,
    required this.isFavorited,
    required this.createdAt,
    this.childId,
    this.firestoreId,
    this.imageURL,
    this.voiceNoteURL,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['caption'] = Variable<String>(caption);
    if (!nullToAbsent || imageData != null) {
      map['image_data'] = Variable<Uint8List>(imageData);
    }
    if (!nullToAbsent || thumbnailData != null) {
      map['thumbnail_data'] = Variable<Uint8List>(thumbnailData);
    }
    if (!nullToAbsent || voiceNoteData != null) {
      map['voice_note_data'] = Variable<Uint8List>(voiceNoteData);
    }
    map['is_favorited'] = Variable<bool>(isFavorited);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || childId != null) {
      map['child_id'] = Variable<int>(childId);
    }
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    if (!nullToAbsent || imageURL != null) {
      map['image_u_r_l'] = Variable<String>(imageURL);
    }
    if (!nullToAbsent || voiceNoteURL != null) {
      map['voice_note_u_r_l'] = Variable<String>(voiceNoteURL);
    }
    return map;
  }

  ArtworksCompanion toCompanion(bool nullToAbsent) {
    return ArtworksCompanion(
      id: Value(id),
      title: Value(title),
      caption: Value(caption),
      imageData: imageData == null && nullToAbsent
          ? const Value.absent()
          : Value(imageData),
      thumbnailData: thumbnailData == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailData),
      voiceNoteData: voiceNoteData == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceNoteData),
      isFavorited: Value(isFavorited),
      createdAt: Value(createdAt),
      childId: childId == null && nullToAbsent
          ? const Value.absent()
          : Value(childId),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      imageURL: imageURL == null && nullToAbsent
          ? const Value.absent()
          : Value(imageURL),
      voiceNoteURL: voiceNoteURL == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceNoteURL),
    );
  }

  factory Artwork.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Artwork(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      caption: serializer.fromJson<String>(json['caption']),
      imageData: serializer.fromJson<Uint8List?>(json['imageData']),
      thumbnailData: serializer.fromJson<Uint8List?>(json['thumbnailData']),
      voiceNoteData: serializer.fromJson<Uint8List?>(json['voiceNoteData']),
      isFavorited: serializer.fromJson<bool>(json['isFavorited']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      childId: serializer.fromJson<int?>(json['childId']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      imageURL: serializer.fromJson<String?>(json['imageURL']),
      voiceNoteURL: serializer.fromJson<String?>(json['voiceNoteURL']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'caption': serializer.toJson<String>(caption),
      'imageData': serializer.toJson<Uint8List?>(imageData),
      'thumbnailData': serializer.toJson<Uint8List?>(thumbnailData),
      'voiceNoteData': serializer.toJson<Uint8List?>(voiceNoteData),
      'isFavorited': serializer.toJson<bool>(isFavorited),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'childId': serializer.toJson<int?>(childId),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'imageURL': serializer.toJson<String?>(imageURL),
      'voiceNoteURL': serializer.toJson<String?>(voiceNoteURL),
    };
  }

  Artwork copyWith({
    int? id,
    String? title,
    String? caption,
    Value<Uint8List?> imageData = const Value.absent(),
    Value<Uint8List?> thumbnailData = const Value.absent(),
    Value<Uint8List?> voiceNoteData = const Value.absent(),
    bool? isFavorited,
    DateTime? createdAt,
    Value<int?> childId = const Value.absent(),
    Value<String?> firestoreId = const Value.absent(),
    Value<String?> imageURL = const Value.absent(),
    Value<String?> voiceNoteURL = const Value.absent(),
  }) => Artwork(
    id: id ?? this.id,
    title: title ?? this.title,
    caption: caption ?? this.caption,
    imageData: imageData.present ? imageData.value : this.imageData,
    thumbnailData: thumbnailData.present
        ? thumbnailData.value
        : this.thumbnailData,
    voiceNoteData: voiceNoteData.present
        ? voiceNoteData.value
        : this.voiceNoteData,
    isFavorited: isFavorited ?? this.isFavorited,
    createdAt: createdAt ?? this.createdAt,
    childId: childId.present ? childId.value : this.childId,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    imageURL: imageURL.present ? imageURL.value : this.imageURL,
    voiceNoteURL: voiceNoteURL.present ? voiceNoteURL.value : this.voiceNoteURL,
  );
  Artwork copyWithCompanion(ArtworksCompanion data) {
    return Artwork(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      caption: data.caption.present ? data.caption.value : this.caption,
      imageData: data.imageData.present ? data.imageData.value : this.imageData,
      thumbnailData: data.thumbnailData.present
          ? data.thumbnailData.value
          : this.thumbnailData,
      voiceNoteData: data.voiceNoteData.present
          ? data.voiceNoteData.value
          : this.voiceNoteData,
      isFavorited: data.isFavorited.present
          ? data.isFavorited.value
          : this.isFavorited,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      childId: data.childId.present ? data.childId.value : this.childId,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      imageURL: data.imageURL.present ? data.imageURL.value : this.imageURL,
      voiceNoteURL: data.voiceNoteURL.present
          ? data.voiceNoteURL.value
          : this.voiceNoteURL,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Artwork(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('caption: $caption, ')
          ..write('imageData: $imageData, ')
          ..write('thumbnailData: $thumbnailData, ')
          ..write('voiceNoteData: $voiceNoteData, ')
          ..write('isFavorited: $isFavorited, ')
          ..write('createdAt: $createdAt, ')
          ..write('childId: $childId, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('imageURL: $imageURL, ')
          ..write('voiceNoteURL: $voiceNoteURL')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    caption,
    $driftBlobEquality.hash(imageData),
    $driftBlobEquality.hash(thumbnailData),
    $driftBlobEquality.hash(voiceNoteData),
    isFavorited,
    createdAt,
    childId,
    firestoreId,
    imageURL,
    voiceNoteURL,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artwork &&
          other.id == this.id &&
          other.title == this.title &&
          other.caption == this.caption &&
          $driftBlobEquality.equals(other.imageData, this.imageData) &&
          $driftBlobEquality.equals(other.thumbnailData, this.thumbnailData) &&
          $driftBlobEquality.equals(other.voiceNoteData, this.voiceNoteData) &&
          other.isFavorited == this.isFavorited &&
          other.createdAt == this.createdAt &&
          other.childId == this.childId &&
          other.firestoreId == this.firestoreId &&
          other.imageURL == this.imageURL &&
          other.voiceNoteURL == this.voiceNoteURL);
}

class ArtworksCompanion extends UpdateCompanion<Artwork> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> caption;
  final Value<Uint8List?> imageData;
  final Value<Uint8List?> thumbnailData;
  final Value<Uint8List?> voiceNoteData;
  final Value<bool> isFavorited;
  final Value<DateTime> createdAt;
  final Value<int?> childId;
  final Value<String?> firestoreId;
  final Value<String?> imageURL;
  final Value<String?> voiceNoteURL;
  const ArtworksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.caption = const Value.absent(),
    this.imageData = const Value.absent(),
    this.thumbnailData = const Value.absent(),
    this.voiceNoteData = const Value.absent(),
    this.isFavorited = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.childId = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.imageURL = const Value.absent(),
    this.voiceNoteURL = const Value.absent(),
  });
  ArtworksCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.caption = const Value.absent(),
    this.imageData = const Value.absent(),
    this.thumbnailData = const Value.absent(),
    this.voiceNoteData = const Value.absent(),
    this.isFavorited = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.childId = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.imageURL = const Value.absent(),
    this.voiceNoteURL = const Value.absent(),
  });
  static Insertable<Artwork> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? caption,
    Expression<Uint8List>? imageData,
    Expression<Uint8List>? thumbnailData,
    Expression<Uint8List>? voiceNoteData,
    Expression<bool>? isFavorited,
    Expression<DateTime>? createdAt,
    Expression<int>? childId,
    Expression<String>? firestoreId,
    Expression<String>? imageURL,
    Expression<String>? voiceNoteURL,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (caption != null) 'caption': caption,
      if (imageData != null) 'image_data': imageData,
      if (thumbnailData != null) 'thumbnail_data': thumbnailData,
      if (voiceNoteData != null) 'voice_note_data': voiceNoteData,
      if (isFavorited != null) 'is_favorited': isFavorited,
      if (createdAt != null) 'created_at': createdAt,
      if (childId != null) 'child_id': childId,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (imageURL != null) 'image_u_r_l': imageURL,
      if (voiceNoteURL != null) 'voice_note_u_r_l': voiceNoteURL,
    });
  }

  ArtworksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? caption,
    Value<Uint8List?>? imageData,
    Value<Uint8List?>? thumbnailData,
    Value<Uint8List?>? voiceNoteData,
    Value<bool>? isFavorited,
    Value<DateTime>? createdAt,
    Value<int?>? childId,
    Value<String?>? firestoreId,
    Value<String?>? imageURL,
    Value<String?>? voiceNoteURL,
  }) {
    return ArtworksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      imageData: imageData ?? this.imageData,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      voiceNoteData: voiceNoteData ?? this.voiceNoteData,
      isFavorited: isFavorited ?? this.isFavorited,
      createdAt: createdAt ?? this.createdAt,
      childId: childId ?? this.childId,
      firestoreId: firestoreId ?? this.firestoreId,
      imageURL: imageURL ?? this.imageURL,
      voiceNoteURL: voiceNoteURL ?? this.voiceNoteURL,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (imageData.present) {
      map['image_data'] = Variable<Uint8List>(imageData.value);
    }
    if (thumbnailData.present) {
      map['thumbnail_data'] = Variable<Uint8List>(thumbnailData.value);
    }
    if (voiceNoteData.present) {
      map['voice_note_data'] = Variable<Uint8List>(voiceNoteData.value);
    }
    if (isFavorited.present) {
      map['is_favorited'] = Variable<bool>(isFavorited.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<int>(childId.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (imageURL.present) {
      map['image_u_r_l'] = Variable<String>(imageURL.value);
    }
    if (voiceNoteURL.present) {
      map['voice_note_u_r_l'] = Variable<String>(voiceNoteURL.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtworksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('caption: $caption, ')
          ..write('imageData: $imageData, ')
          ..write('thumbnailData: $thumbnailData, ')
          ..write('voiceNoteData: $voiceNoteData, ')
          ..write('isFavorited: $isFavorited, ')
          ..write('createdAt: $createdAt, ')
          ..write('childId: $childId, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('imageURL: $imageURL, ')
          ..write('voiceNoteURL: $voiceNoteURL')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  const Tag({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Tag copyWith({int? id, String? name}) =>
      Tag(id: id ?? this.id, name: name ?? this.name);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TagsCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TagsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ArtworkTagsTable extends ArtworkTags
    with TableInfo<$ArtworkTagsTable, ArtworkTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtworkTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _artworkIdMeta = const VerificationMeta(
    'artworkId',
  );
  @override
  late final GeneratedColumn<int> artworkId = GeneratedColumn<int>(
    'artwork_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artworks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [artworkId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artwork_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArtworkTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('artwork_id')) {
      context.handle(
        _artworkIdMeta,
        artworkId.isAcceptableOrUnknown(data['artwork_id']!, _artworkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artworkIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {artworkId, tagId};
  @override
  ArtworkTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtworkTag(
      artworkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artwork_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $ArtworkTagsTable createAlias(String alias) {
    return $ArtworkTagsTable(attachedDatabase, alias);
  }
}

class ArtworkTag extends DataClass implements Insertable<ArtworkTag> {
  final int artworkId;
  final int tagId;
  const ArtworkTag({required this.artworkId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['artwork_id'] = Variable<int>(artworkId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  ArtworkTagsCompanion toCompanion(bool nullToAbsent) {
    return ArtworkTagsCompanion(
      artworkId: Value(artworkId),
      tagId: Value(tagId),
    );
  }

  factory ArtworkTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtworkTag(
      artworkId: serializer.fromJson<int>(json['artworkId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'artworkId': serializer.toJson<int>(artworkId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  ArtworkTag copyWith({int? artworkId, int? tagId}) => ArtworkTag(
    artworkId: artworkId ?? this.artworkId,
    tagId: tagId ?? this.tagId,
  );
  ArtworkTag copyWithCompanion(ArtworkTagsCompanion data) {
    return ArtworkTag(
      artworkId: data.artworkId.present ? data.artworkId.value : this.artworkId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtworkTag(')
          ..write('artworkId: $artworkId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(artworkId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtworkTag &&
          other.artworkId == this.artworkId &&
          other.tagId == this.tagId);
}

class ArtworkTagsCompanion extends UpdateCompanion<ArtworkTag> {
  final Value<int> artworkId;
  final Value<int> tagId;
  final Value<int> rowid;
  const ArtworkTagsCompanion({
    this.artworkId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArtworkTagsCompanion.insert({
    required int artworkId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : artworkId = Value(artworkId),
       tagId = Value(tagId);
  static Insertable<ArtworkTag> custom({
    Expression<int>? artworkId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (artworkId != null) 'artwork_id': artworkId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArtworkTagsCompanion copyWith({
    Value<int>? artworkId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return ArtworkTagsCompanion(
      artworkId: artworkId ?? this.artworkId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (artworkId.present) {
      map['artwork_id'] = Variable<int>(artworkId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtworkTagsCompanion(')
          ..write('artworkId: $artworkId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChildrenTable children = $ChildrenTable(this);
  late final $ArtworksTable artworks = $ArtworksTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ArtworkTagsTable artworkTags = $ArtworkTagsTable(this);
  late final ChildDao childDao = ChildDao(this as AppDatabase);
  late final ArtworkDao artworkDao = ArtworkDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    children,
    artworks,
    tags,
    artworkTags,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'children',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('artworks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'artworks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('artwork_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('artwork_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ChildrenTableCreateCompanionBuilder =
    ChildrenCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> avatarColor,
      Value<DateTime> createdAt,
      Value<Uint8List?> avatarImageData,
      Value<String?> firestoreId,
      Value<bool> isShared,
      Value<String?> ownerUserId,
    });
typedef $$ChildrenTableUpdateCompanionBuilder =
    ChildrenCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> avatarColor,
      Value<DateTime> createdAt,
      Value<Uint8List?> avatarImageData,
      Value<String?> firestoreId,
      Value<bool> isShared,
      Value<String?> ownerUserId,
    });

final class $$ChildrenTableReferences
    extends BaseReferences<_$AppDatabase, $ChildrenTable, Child> {
  $$ChildrenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ArtworksTable, List<Artwork>> _artworksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.artworks,
    aliasName: $_aliasNameGenerator(db.children.id, db.artworks.childId),
  );

  $$ArtworksTableProcessedTableManager get artworksRefs {
    final manager = $$ArtworksTableTableManager(
      $_db,
      $_db.artworks,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_artworksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChildrenTableFilterComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get avatarImageData => $composableBuilder(
    column: $table.avatarImageData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> artworksRefs(
    Expression<bool> Function($$ArtworksTableFilterComposer f) f,
  ) {
    final $$ArtworksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableFilterComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get avatarImageData => $composableBuilder(
    column: $table.avatarImageData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChildrenTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<Uint8List> get avatarImageData => $composableBuilder(
    column: $table.avatarImageData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isShared =>
      $composableBuilder(column: $table.isShared, builder: (column) => column);

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  Expression<T> artworksRefs<T extends Object>(
    Expression<T> Function($$ArtworksTableAnnotationComposer a) f,
  ) {
    final $$ArtworksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableAnnotationComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildrenTable,
          Child,
          $$ChildrenTableFilterComposer,
          $$ChildrenTableOrderingComposer,
          $$ChildrenTableAnnotationComposer,
          $$ChildrenTableCreateCompanionBuilder,
          $$ChildrenTableUpdateCompanionBuilder,
          (Child, $$ChildrenTableReferences),
          Child,
          PrefetchHooks Function({bool artworksRefs})
        > {
  $$ChildrenTableTableManager(_$AppDatabase db, $ChildrenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildrenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildrenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildrenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> avatarColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<Uint8List?> avatarImageData = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
              }) => ChildrenCompanion(
                id: id,
                name: name,
                avatarColor: avatarColor,
                createdAt: createdAt,
                avatarImageData: avatarImageData,
                firestoreId: firestoreId,
                isShared: isShared,
                ownerUserId: ownerUserId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> avatarColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<Uint8List?> avatarImageData = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
              }) => ChildrenCompanion.insert(
                id: id,
                name: name,
                avatarColor: avatarColor,
                createdAt: createdAt,
                avatarImageData: avatarImageData,
                firestoreId: firestoreId,
                isShared: isShared,
                ownerUserId: ownerUserId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChildrenTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({artworksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (artworksRefs) db.artworks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (artworksRefs)
                    await $_getPrefetchedData<Child, $ChildrenTable, Artwork>(
                      currentTable: table,
                      referencedTable: $$ChildrenTableReferences
                          ._artworksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChildrenTableReferences(db, table, p0).artworksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.childId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChildrenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildrenTable,
      Child,
      $$ChildrenTableFilterComposer,
      $$ChildrenTableOrderingComposer,
      $$ChildrenTableAnnotationComposer,
      $$ChildrenTableCreateCompanionBuilder,
      $$ChildrenTableUpdateCompanionBuilder,
      (Child, $$ChildrenTableReferences),
      Child,
      PrefetchHooks Function({bool artworksRefs})
    >;
typedef $$ArtworksTableCreateCompanionBuilder =
    ArtworksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> caption,
      Value<Uint8List?> imageData,
      Value<Uint8List?> thumbnailData,
      Value<Uint8List?> voiceNoteData,
      Value<bool> isFavorited,
      Value<DateTime> createdAt,
      Value<int?> childId,
      Value<String?> firestoreId,
      Value<String?> imageURL,
      Value<String?> voiceNoteURL,
    });
typedef $$ArtworksTableUpdateCompanionBuilder =
    ArtworksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> caption,
      Value<Uint8List?> imageData,
      Value<Uint8List?> thumbnailData,
      Value<Uint8List?> voiceNoteData,
      Value<bool> isFavorited,
      Value<DateTime> createdAt,
      Value<int?> childId,
      Value<String?> firestoreId,
      Value<String?> imageURL,
      Value<String?> voiceNoteURL,
    });

final class $$ArtworksTableReferences
    extends BaseReferences<_$AppDatabase, $ArtworksTable, Artwork> {
  $$ArtworksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) => db.children
      .createAlias($_aliasNameGenerator(db.artworks.childId, db.children.id));

  $$ChildrenTableProcessedTableManager? get childId {
    final $_column = $_itemColumn<int>('child_id');
    if ($_column == null) return null;
    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ArtworkTagsTable, List<ArtworkTag>>
  _artworkTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.artworkTags,
    aliasName: $_aliasNameGenerator(db.artworks.id, db.artworkTags.artworkId),
  );

  $$ArtworkTagsTableProcessedTableManager get artworkTagsRefs {
    final manager = $$ArtworkTagsTableTableManager(
      $_db,
      $_db.artworkTags,
    ).filter((f) => f.artworkId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_artworkTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArtworksTableFilterComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get imageData => $composableBuilder(
    column: $table.imageData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get thumbnailData => $composableBuilder(
    column: $table.thumbnailData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get voiceNoteData => $composableBuilder(
    column: $table.voiceNoteData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorited => $composableBuilder(
    column: $table.isFavorited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageURL => $composableBuilder(
    column: $table.imageURL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceNoteURL => $composableBuilder(
    column: $table.voiceNoteURL,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> artworkTagsRefs(
    Expression<bool> Function($$ArtworkTagsTableFilterComposer f) f,
  ) {
    final $$ArtworkTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworkTags,
      getReferencedColumn: (t) => t.artworkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworkTagsTableFilterComposer(
            $db: $db,
            $table: $db.artworkTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArtworksTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get imageData => $composableBuilder(
    column: $table.imageData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get thumbnailData => $composableBuilder(
    column: $table.thumbnailData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get voiceNoteData => $composableBuilder(
    column: $table.voiceNoteData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorited => $composableBuilder(
    column: $table.isFavorited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageURL => $composableBuilder(
    column: $table.imageURL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceNoteURL => $composableBuilder(
    column: $table.voiceNoteURL,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtworksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<Uint8List> get imageData =>
      $composableBuilder(column: $table.imageData, builder: (column) => column);

  GeneratedColumn<Uint8List> get thumbnailData => $composableBuilder(
    column: $table.thumbnailData,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get voiceNoteData => $composableBuilder(
    column: $table.voiceNoteData,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorited => $composableBuilder(
    column: $table.isFavorited,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageURL =>
      $composableBuilder(column: $table.imageURL, builder: (column) => column);

  GeneratedColumn<String> get voiceNoteURL => $composableBuilder(
    column: $table.voiceNoteURL,
    builder: (column) => column,
  );

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> artworkTagsRefs<T extends Object>(
    Expression<T> Function($$ArtworkTagsTableAnnotationComposer a) f,
  ) {
    final $$ArtworkTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworkTags,
      getReferencedColumn: (t) => t.artworkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworkTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.artworkTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArtworksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtworksTable,
          Artwork,
          $$ArtworksTableFilterComposer,
          $$ArtworksTableOrderingComposer,
          $$ArtworksTableAnnotationComposer,
          $$ArtworksTableCreateCompanionBuilder,
          $$ArtworksTableUpdateCompanionBuilder,
          (Artwork, $$ArtworksTableReferences),
          Artwork,
          PrefetchHooks Function({bool childId, bool artworkTagsRefs})
        > {
  $$ArtworksTableTableManager(_$AppDatabase db, $ArtworksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtworksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtworksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtworksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<Uint8List?> imageData = const Value.absent(),
                Value<Uint8List?> thumbnailData = const Value.absent(),
                Value<Uint8List?> voiceNoteData = const Value.absent(),
                Value<bool> isFavorited = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> childId = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<String?> imageURL = const Value.absent(),
                Value<String?> voiceNoteURL = const Value.absent(),
              }) => ArtworksCompanion(
                id: id,
                title: title,
                caption: caption,
                imageData: imageData,
                thumbnailData: thumbnailData,
                voiceNoteData: voiceNoteData,
                isFavorited: isFavorited,
                createdAt: createdAt,
                childId: childId,
                firestoreId: firestoreId,
                imageURL: imageURL,
                voiceNoteURL: voiceNoteURL,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<Uint8List?> imageData = const Value.absent(),
                Value<Uint8List?> thumbnailData = const Value.absent(),
                Value<Uint8List?> voiceNoteData = const Value.absent(),
                Value<bool> isFavorited = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> childId = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<String?> imageURL = const Value.absent(),
                Value<String?> voiceNoteURL = const Value.absent(),
              }) => ArtworksCompanion.insert(
                id: id,
                title: title,
                caption: caption,
                imageData: imageData,
                thumbnailData: thumbnailData,
                voiceNoteData: voiceNoteData,
                isFavorited: isFavorited,
                createdAt: createdAt,
                childId: childId,
                firestoreId: firestoreId,
                imageURL: imageURL,
                voiceNoteURL: voiceNoteURL,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ArtworksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false, artworkTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (artworkTagsRefs) db.artworkTags],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.childId,
                                referencedTable: $$ArtworksTableReferences
                                    ._childIdTable(db),
                                referencedColumn: $$ArtworksTableReferences
                                    ._childIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (artworkTagsRefs)
                    await $_getPrefetchedData<
                      Artwork,
                      $ArtworksTable,
                      ArtworkTag
                    >(
                      currentTable: table,
                      referencedTable: $$ArtworksTableReferences
                          ._artworkTagsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ArtworksTableReferences(
                        db,
                        table,
                        p0,
                      ).artworkTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.artworkId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ArtworksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtworksTable,
      Artwork,
      $$ArtworksTableFilterComposer,
      $$ArtworksTableOrderingComposer,
      $$ArtworksTableAnnotationComposer,
      $$ArtworksTableCreateCompanionBuilder,
      $$ArtworksTableUpdateCompanionBuilder,
      (Artwork, $$ArtworksTableReferences),
      Artwork,
      PrefetchHooks Function({bool childId, bool artworkTagsRefs})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({Value<int> id, required String name});
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({Value<int> id, Value<String> name});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ArtworkTagsTable, List<ArtworkTag>>
  _artworkTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.artworkTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.artworkTags.tagId),
  );

  $$ArtworkTagsTableProcessedTableManager get artworkTagsRefs {
    final manager = $$ArtworkTagsTableTableManager(
      $_db,
      $_db.artworkTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_artworkTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> artworkTagsRefs(
    Expression<bool> Function($$ArtworkTagsTableFilterComposer f) f,
  ) {
    final $$ArtworkTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworkTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworkTagsTableFilterComposer(
            $db: $db,
            $table: $db.artworkTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> artworkTagsRefs<T extends Object>(
    Expression<T> Function($$ArtworkTagsTableAnnotationComposer a) f,
  ) {
    final $$ArtworkTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artworkTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworkTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.artworkTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool artworkTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TagsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TagsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({artworkTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (artworkTagsRefs) db.artworkTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (artworkTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, ArtworkTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._artworkTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).artworkTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool artworkTagsRefs})
    >;
typedef $$ArtworkTagsTableCreateCompanionBuilder =
    ArtworkTagsCompanion Function({
      required int artworkId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$ArtworkTagsTableUpdateCompanionBuilder =
    ArtworkTagsCompanion Function({
      Value<int> artworkId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$ArtworkTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ArtworkTagsTable, ArtworkTag> {
  $$ArtworkTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ArtworksTable _artworkIdTable(_$AppDatabase db) =>
      db.artworks.createAlias(
        $_aliasNameGenerator(db.artworkTags.artworkId, db.artworks.id),
      );

  $$ArtworksTableProcessedTableManager get artworkId {
    final $_column = $_itemColumn<int>('artwork_id')!;

    final manager = $$ArtworksTableTableManager(
      $_db,
      $_db.artworks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artworkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) => db.tags.createAlias(
    $_aliasNameGenerator(db.artworkTags.tagId, db.tags.id),
  );

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArtworkTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ArtworkTagsTable> {
  $$ArtworkTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ArtworksTableFilterComposer get artworkId {
    final $$ArtworksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artworkId,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableFilterComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtworkTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtworkTagsTable> {
  $$ArtworkTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ArtworksTableOrderingComposer get artworkId {
    final $$ArtworksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artworkId,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableOrderingComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtworkTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtworkTagsTable> {
  $$ArtworkTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ArtworksTableAnnotationComposer get artworkId {
    final $$ArtworksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artworkId,
      referencedTable: $db.artworks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtworksTableAnnotationComposer(
            $db: $db,
            $table: $db.artworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtworkTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtworkTagsTable,
          ArtworkTag,
          $$ArtworkTagsTableFilterComposer,
          $$ArtworkTagsTableOrderingComposer,
          $$ArtworkTagsTableAnnotationComposer,
          $$ArtworkTagsTableCreateCompanionBuilder,
          $$ArtworkTagsTableUpdateCompanionBuilder,
          (ArtworkTag, $$ArtworkTagsTableReferences),
          ArtworkTag,
          PrefetchHooks Function({bool artworkId, bool tagId})
        > {
  $$ArtworkTagsTableTableManager(_$AppDatabase db, $ArtworkTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtworkTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtworkTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtworkTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> artworkId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtworkTagsCompanion(
                artworkId: artworkId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int artworkId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => ArtworkTagsCompanion.insert(
                artworkId: artworkId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ArtworkTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({artworkId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (artworkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.artworkId,
                                referencedTable: $$ArtworkTagsTableReferences
                                    ._artworkIdTable(db),
                                referencedColumn: $$ArtworkTagsTableReferences
                                    ._artworkIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$ArtworkTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$ArtworkTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ArtworkTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtworkTagsTable,
      ArtworkTag,
      $$ArtworkTagsTableFilterComposer,
      $$ArtworkTagsTableOrderingComposer,
      $$ArtworkTagsTableAnnotationComposer,
      $$ArtworkTagsTableCreateCompanionBuilder,
      $$ArtworkTagsTableUpdateCompanionBuilder,
      (ArtworkTag, $$ArtworkTagsTableReferences),
      ArtworkTag,
      PrefetchHooks Function({bool artworkId, bool tagId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChildrenTableTableManager get children =>
      $$ChildrenTableTableManager(_db, _db.children);
  $$ArtworksTableTableManager get artworks =>
      $$ArtworksTableTableManager(_db, _db.artworks);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ArtworkTagsTableTableManager get artworkTags =>
      $$ArtworkTagsTableTableManager(_db, _db.artworkTags);
}
