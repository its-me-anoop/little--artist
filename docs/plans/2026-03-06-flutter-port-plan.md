# Little Artist Flutter Port — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Recreate the Little Artist iOS app as a cross-platform Flutter app sharing the same Firebase backend.

**Architecture:** Riverpod for state management, Isar for offline-first local persistence, GoRouter for navigation. Dual-write pattern (Isar + Firestore) mirrors the iOS app. Same Firebase project so both apps share data.

**Tech Stack:** Flutter 3.x, Riverpod, Isar, GoRouter, Firebase (Auth/Firestore/Storage), firebase_vertexai, in_app_purchase, Google Fonts Nunito.

---

## Phase 1: Project Foundation

### Task 1: Scaffold Flutter Project

**Files:**
- Create: `little_artist_flutter/` (Flutter project)
- Create: `little_artist_flutter/pubspec.yaml`

**Step 1: Create Flutter project**

```bash
cd "/Users/anoopjose/Projects/Little Artist"
flutter create little_artist_flutter --org uk.co.flutterly --project-name little_artist
```

**Step 2: Replace pubspec.yaml dependencies**

```yaml
name: little_artist
description: Archive and celebrate children's artwork.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.6.0
  flutter: ">=3.27.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Local database
  isar: ^4.0.0-dev.14
  isar_flutter_libs: ^4.0.0-dev.14

  # Navigation
  go_router: ^14.8.1

  # Firebase
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1
  cloud_firestore: ^5.6.5
  firebase_storage: ^12.4.4
  firebase_vertexai: ^1.2.0

  # Auth providers
  sign_in_with_apple: ^6.1.4
  google_sign_in: ^6.2.2
  crypto: ^3.0.6

  # Media
  image_picker: ^1.1.2
  cunning_document_scanner: ^2.0.2
  flutter_image_compress: ^2.3.0

  # Audio
  record: ^5.2.0
  just_audio: ^0.9.43

  # PDF
  pdf: ^3.11.2
  printing: ^5.13.5

  # Notifications
  flutter_local_notifications: ^18.0.1

  # IAP
  in_app_purchase: ^3.2.0

  # Fonts
  google_fonts: ^6.2.1

  # Utilities
  path_provider: ^2.1.5
  permission_handler: ^11.3.1
  share_plus: ^10.1.4
  url_launcher: ^6.3.1
  shared_preferences: ^2.3.5
  intl: ^0.19.0
  uuid: ^4.5.1
  collection: ^1.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  isar_generator: ^4.0.0-dev.14
  build_runner: ^2.4.14
  riverpod_generator: ^2.6.3
  custom_lint:

flutter:
  uses-material-design: true
```

**Step 3: Run flutter pub get**

```bash
cd "/Users/anoopjose/Projects/Little Artist/little_artist_flutter"
flutter pub get
```

**Step 4: Verify project builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```

**Step 5: Commit**

```bash
git add little_artist_flutter/
git commit -m "feat: scaffold Flutter project with dependencies"
```

---

### Task 2: Firebase Configuration

**Files:**
- Modify: `little_artist_flutter/android/` (google-services.json)
- Modify: `little_artist_flutter/ios/` (GoogleService-Info.plist)
- Create: `little_artist_flutter/lib/firebase_options.dart`

**Step 1: Install FlutterFire CLI and configure**

```bash
dart pub global activate flutterfire_cli
cd "/Users/anoopjose/Projects/Little Artist/little_artist_flutter"
flutterfire configure --project=little-artist-flutterly
```

Select both iOS and Android platforms. This generates `firebase_options.dart` and platform configs.

**Step 2: Verify firebase_options.dart was created**

Check that `lib/firebase_options.dart` exists with `DefaultFirebaseOptions`.

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: configure Firebase for iOS and Android"
```

---

### Task 3: Design Tokens

**Files:**
- Create: `little_artist_flutter/lib/utils/brand_tokens.dart`
- Create: `little_artist_flutter/lib/utils/color_hex.dart`

**Step 1: Create color hex extension**

```dart
// lib/utils/color_hex.dart
import 'package:flutter/material.dart';

extension ColorHex on Color {
  /// Creates a Color from a hex string (e.g. "F2784B" or "#F2784B").
  static Color fromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
```

**Step 2: Create brand tokens**

Port every token from `BrandTokens.swift`. All colors, fonts, spacing, radii, sizes, shadows.

```dart
// lib/utils/brand_tokens.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_hex.dart';

abstract final class Brand {
  // ── Colors ──
  static const Color primary = Color(0xFFF2784B);
  static Color get primaryTint => primary.withValues(alpha: 0.12);
  static const Color cream = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFBF7);
  static const Color charcoal = Color(0xFF3D3D3D);
  static const Color warmGray = Color(0xFF8A8680);
  static const Color softTan = Color(0xFFE8E0D8);
  static const Color sage = Color(0xFFA8C5A0);
  static const Color sky = Color(0xFF7EB8DA);
  static const Color lavender = Color(0xFFB8A9D4);
  static const Color dustyRose = Color(0xFFD4736C);
  static const Color disabled = Color(0xFF8A8680);

  // Dark mode variants
  static const Color creamDark = Color(0xFF1C1C1E);
  static const Color surfaceDark = Color(0xFF2C2C2C);
  static const Color charcoalDark = Color(0xFFE5E5EA);
  static const Color warmGrayDark = Color(0xFF9E9EA3);

  // ── Avatar Palette ──
  static const List<String> avatarColors = [
    'F2784B', 'A8C5A0', '7EB8DA', 'B8A9D4', 'E8C94A', 'D4928A', '7BC8B5',
  ];
  static const String defaultAvatarColor = 'F2784B';

  // ── Typography ──
  static TextStyle get displayFont =>
      GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w700);
  static TextStyle get title1Font =>
      GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w700);
  static TextStyle get title2Font =>
      GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w600);
  static TextStyle get title3Font =>
      GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w500);
  static TextStyle get headlineFont =>
      GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w600);
  static TextStyle get bodyFont => const TextStyle(fontSize: 17);
  static TextStyle get subheadlineFont => const TextStyle(fontSize: 15);
  static TextStyle get captionFont => const TextStyle(fontSize: 12);
  static TextStyle get caption2Font => const TextStyle(fontSize: 11);

  // ── Corner Radii ──
  static const double radiusOnboarding = 40;
  static const double radiusSheet = 20;
  static const double radiusCard = 18;
  static const double radiusButton = 16;
  static const double radiusField = 14;
  static const double radiusImage = 12;

  // ── Spacing ──
  static const double screenPadding = 20;
  static const double formPadding = 32;
  static const double sectionSpacing = 28;
  static const double gallerySpacing = 24;
  static const double buttonPadding = 18;
  static const double fieldPadding = 14;

  // ── Component Sizes ──
  static const double avatarSize = 60;
  static const double avatarRingSize = 68;
  static const double avatarRingStroke = 3;
  static const double avatarPreviewSize = 110;
  static const double sourceButtonSize = 56;
  static const double thumbnailWidth = 164;
  static const double thumbnailHeight = 180;
  static const double fabSize = 60;
  static const double onboardingCardHeight = 340;
  static const double colorCircleSize = 40;

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: charcoal.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get avatarShadow => [
    BoxShadow(
      color: charcoal.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get fabShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.40),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Theme ──
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.light(
      primary: primary,
      surface: surface,
      error: dustyRose,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cream,
      foregroundColor: charcoal,
      elevation: 0,
      titleTextStyle: title2Font.copyWith(color: charcoal),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: warmGray,
      indicatorColor: primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      elevation: 0,
    ),
    dividerColor: softTan,
    textTheme: TextTheme(
      displayLarge: displayFont.copyWith(color: charcoal),
      titleLarge: title1Font.copyWith(color: charcoal),
      titleMedium: title2Font.copyWith(color: charcoal),
      titleSmall: title3Font.copyWith(color: charcoal),
      headlineSmall: headlineFont.copyWith(color: charcoal),
      bodyLarge: bodyFont.copyWith(color: charcoal),
      bodyMedium: subheadlineFont.copyWith(color: charcoal),
      labelSmall: captionFont.copyWith(color: warmGray),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: creamDark,
    colorScheme: ColorScheme.dark(
      primary: primary,
      surface: surfaceDark,
      error: dustyRose,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: creamDark,
      foregroundColor: charcoalDark,
      elevation: 0,
      titleTextStyle: title2Font.copyWith(color: charcoalDark),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: warmGrayDark,
      indicatorColor: primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      elevation: 0,
    ),
    dividerColor: warmGrayDark.withValues(alpha: 0.3),
    textTheme: TextTheme(
      displayLarge: displayFont.copyWith(color: charcoalDark),
      titleLarge: title1Font.copyWith(color: charcoalDark),
      titleMedium: title2Font.copyWith(color: charcoalDark),
      titleSmall: title3Font.copyWith(color: charcoalDark),
      headlineSmall: headlineFont.copyWith(color: charcoalDark),
      bodyLarge: bodyFont.copyWith(color: charcoalDark),
      bodyMedium: subheadlineFont.copyWith(color: charcoalDark),
      labelSmall: captionFont.copyWith(color: warmGrayDark),
    ),
  );
}
```

**Step 3: Verify tokens compile**

```bash
cd "/Users/anoopjose/Projects/Little Artist/little_artist_flutter"
flutter analyze lib/utils/
```

**Step 4: Commit**

```bash
git add lib/utils/
git commit -m "feat: add brand design tokens and theme"
```

---

### Task 4: App Shell with Navigation

**Files:**
- Create: `little_artist_flutter/lib/main.dart`
- Create: `little_artist_flutter/lib/app.dart`

**Step 1: Create main.dart with Firebase init**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: LittleArtistApp()));
}
```

**Step 2: Create app.dart with tab navigation**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'utils/brand_tokens.dart';

// Placeholder views — will be replaced in later tasks
class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(title, style: Brand.title1Font)),
  );
}

final _router = GoRouter(
  initialLocation: '/gallery',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ScaffoldWithNavBar(
        navigationShell: navigationShell,
      ),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/gallery', builder: (_, __) => const _Placeholder('Gallery')),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/timeline', builder: (_, __) => const _Placeholder('Timeline')),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/milestones', builder: (_, __) => const _Placeholder('Milestones')),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const _Placeholder('Settings')),
        ]),
      ],
    ),
  ],
);

class LittleArtistApp extends ConsumerWidget {
  const LittleArtistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Little Artist',
      theme: Brand.lightTheme,
      darkTheme: Brand.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor: Brand.cream,
        indicatorColor: Brand.primaryTint,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Gallery'),
          NavigationDestination(icon: Icon(Icons.timeline_outlined), selectedIcon: Icon(Icons.timeline), label: 'Timeline'),
          NavigationDestination(icon: Icon(Icons.star_outline), selectedIcon: Icon(Icons.star), label: 'Milestones'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
```

**Step 3: Verify app runs**

```bash
flutter run --debug
```

Verify: 4-tab navigation bar appears with Gallery, Timeline, Milestones, Settings.

**Step 4: Commit**

```bash
git add lib/
git commit -m "feat: add app shell with tab navigation"
```

---

## Phase 2: Data Layer

### Task 5: Isar Models

**Files:**
- Create: `little_artist_flutter/lib/models/child.dart`
- Create: `little_artist_flutter/lib/models/artwork.dart`
- Create: `little_artist_flutter/lib/models/tag.dart`

**Step 1: Create Child model**

```dart
// lib/models/child.dart
import 'package:isar/isar.dart';

part 'child.g.dart';

@collection
class Child {
  Id id = Isar.autoIncrement;

  String name = '';
  String avatarColor = 'F2784B';
  DateTime createdAt = DateTime.now();
  List<byte>? avatarImageData;
  String? firestoreId;
  bool isShared = false;
  String? ownerUserId;

  final artworks = IsarLinks<Artwork>();
}
```

Note: `Artwork` import will be added after creating artwork.dart.

**Step 2: Create Artwork model**

```dart
// lib/models/artwork.dart
import 'package:isar/isar.dart';
import 'child.dart';
import 'tag.dart';

part 'artwork.g.dart';

@collection
class Artwork {
  Id id = Isar.autoIncrement;

  String title = '';
  String caption = '';
  List<byte>? imageData;
  List<byte>? thumbnailData;
  List<byte>? voiceNoteData;
  bool isFavorited = false;
  DateTime createdAt = DateTime.now();
  String? firestoreId;
  String? imageURL;
  String? voiceNoteURL;

  @Backlink(to: 'artworks')
  final child = IsarLink<Child>();

  final tags = IsarLinks<Tag>();
}
```

**Step 3: Create Tag model**

```dart
// lib/models/tag.dart
import 'package:isar/isar.dart';
import 'artwork.dart';

part 'tag.g.dart';

@collection
class Tag {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String name = '';

  @Backlink(to: 'tags')
  final artworks = IsarLinks<Artwork>();
}
```

**Step 4: Run Isar code generation**

```bash
cd "/Users/anoopjose/Projects/Little Artist/little_artist_flutter"
dart run build_runner build --delete-conflicting-outputs
```

**Step 5: Verify generated files exist**

```bash
ls lib/models/*.g.dart
```

Expected: `child.g.dart`, `artwork.g.dart`, `tag.g.dart`

**Step 6: Commit**

```bash
git add lib/models/
git commit -m "feat: add Isar data models (Child, Artwork, Tag)"
```

---

### Task 6: Isar Database Provider

**Files:**
- Create: `little_artist_flutter/lib/providers/database_provider.dart`

**Step 1: Create database provider**

```dart
// lib/providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/child.dart';
import '../models/artwork.dart';
import '../models/tag.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [ChildSchema, ArtworkSchema, TagSchema],
    directory: dir.path,
  );
});
```

**Step 2: Update main.dart to await Isar**

Update `main.dart` to initialize Isar before `runApp`, or let consumers use `ref.watch(isarProvider)` with loading states.

**Step 3: Commit**

```bash
git add lib/providers/
git commit -m "feat: add Isar database provider"
```

---

## Phase 3: Core Services

### Task 7: Firebase Auth Service

**Files:**
- Create: `little_artist_flutter/lib/services/firebase_auth_service.dart`
- Create: `little_artist_flutter/lib/providers/auth_provider.dart`

**Step 1: Create auth service**

Port `FirebaseAuthService.swift` logic:
- `signInAnonymously()` — anonymous sign-in on first launch
- `signInWithApple()` — Apple credential linking to anonymous account
- `signOut()` — sign out and re-auth anonymous
- `deleteAccount()` — delete account and fall back to anonymous
- `isLinkedWithApple` — check if Apple provider linked
- `currentUser` — stream of auth state

Key implementation details from iOS:
- Uses `crypto` package for SHA256 nonce
- Uses `sign_in_with_apple` package for Apple auth
- Links Apple credential to existing anonymous account via `linkWithCredential`
- On link failure (credential-already-in-use), signs in directly with Apple credential
- After sign-out, re-authenticates anonymously

**Step 2: Create auth provider**

```dart
// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_auth_service.dart';

final firebaseAuthServiceProvider = Provider((ref) => FirebaseAuthService());

final authStateProvider = StreamProvider((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});
```

**Step 3: Verify auth compiles**

```bash
flutter analyze lib/services/firebase_auth_service.dart lib/providers/auth_provider.dart
```

**Step 4: Commit**

```bash
git add lib/services/firebase_auth_service.dart lib/providers/auth_provider.dart
git commit -m "feat: add Firebase auth service with anonymous + Apple sign-in"
```

---

### Task 8: Storage Service

**Files:**
- Create: `little_artist_flutter/lib/services/storage_service.dart`

**Step 1: Create storage service**

Port `StorageService.swift`:
- `upload(data, path, contentType)` — returns download URL
- `uploadWithRetry(data, path, contentType)` — 3 attempts, exponential backoff (1s, 2s, 4s)
- `download(path)` — max 20MB
- `downloadUrl(url)` — from full URL
- `delete(path)` — deletes file at path
- Path generators: `avatarPath(uid, childId)`, `artworkImagePath(uid, childId, artworkId)`, `voiceNotePath(uid, childId, artworkId)`

**Step 2: Commit**

```bash
git add lib/services/storage_service.dart
git commit -m "feat: add Firebase Storage service with retry"
```

---

### Task 9: Image Processing Service

**Files:**
- Create: `little_artist_flutter/lib/services/image_processing_service.dart`

**Step 1: Create image processing service**

Port `ImageProcessingService.swift`:
- `processForStorage(Uint8List imageBytes)` — returns `(imageData, thumbnailData)`
- Main image: max 2048px, JPEG quality 70
- Thumbnail: max 512px, JPEG quality 60
- Use `flutter_image_compress` for resizing and compression
- Aspect-ratio-preserving resize

**Step 2: Commit**

```bash
git add lib/services/image_processing_service.dart
git commit -m "feat: add image processing service"
```

---

### Task 10: Firestore Repository

**Files:**
- Create: `little_artist_flutter/lib/services/firestore_repository.dart`

**Step 1: Create Firestore repository**

Port `FirestoreRepository.swift` (937 lines). This is the largest service. Key methods:

**Children:**
- `createChild(Child child, Isar isar)` — write to Isar, async to Firestore with pre-generated ID
- `updateChild(Child child, Isar isar)` — update local + remote
- `deleteChild(Child child, Isar isar)` — cascade delete artworks, clean Storage

**Artworks:**
- `createArtwork(Artwork artwork, Child child, Isar isar)` — dual write, upload image/thumbnail
- `batchCreateArtworks(List<Artwork>, Child, Isar)` — offset dates by index to avoid collisions
- `updateArtwork(Artwork, Isar)` — update metadata, re-upload changed binaries
- `deleteArtwork(Artwork, Isar)` — remove from Isar + Firestore + Storage

**Sharing:**
- `shareChild(Child)` — create share doc with ownerUserId, childId
- `acceptShare(shareId)` — add current user as participant
- `stopSharing(shareId)` — set status to revoked
- `leaveShare(shareId)` — remove self from participants
- `fetchParticipants(shareId)` — get participant list
- `findShare(childFirestoreId)` — locate active share

**Bulk:**
- `uploadAllLocalData(Isar)` — one-time upload when premium enabled
- `deleteAllUserData(Isar)` — wipe everything
- `syncUserPreferencesToFirestore()` — sync UserDefaults/SharedPreferences

**Important patterns:**
- `localWriteIds: Set<String>` — track local writes for echo suppression in sync service
- Pre-generate Firestore document IDs to prevent duplicates on retry
- Premium gating: only sync artworks if premium, always sync children

**Step 2: Commit**

```bash
git add lib/services/firestore_repository.dart
git commit -m "feat: add Firestore repository with dual-write pattern"
```

---

### Task 11: Firestore Sync Service

**Files:**
- Create: `little_artist_flutter/lib/services/firestore_sync_service.dart`
- Create: `little_artist_flutter/lib/providers/sync_provider.dart`

**Step 1: Create sync service**

Port `FirestoreSyncService.swift` (690 lines). Key functionality:

**Listeners:**
- `start()` — begin all snapshot listeners
- `stop()` — detach all listeners
- `listenToChildren()` — children collection snapshots
- `listenToArtworks(childFirestoreId)` — artwork subcollection per child
- `listenToShares()` — shares collection with participant check
- `checkAndListenToSharedChild(shareDoc)` — listen to shared child + artworks

**Reconciliation:**
- `upsertChild(doc, Isar)` — create or update local child from Firestore doc
- `removeChild(firestoreId, Isar)` — delete local child
- `upsertArtwork(doc, childFirestoreId, Isar)` — create or update local artwork
- `removeArtwork(firestoreId, Isar)` — delete local artwork

**Key patterns:**
- Echo write suppression via `localWriteIds` set (shared with FirestoreRepository)
- One-time deduplication after initial children snapshot (merge by name, keep child with most artworks)
- Download images from `imageURL` and store in Isar for offline access
- Auto-generate thumbnails for downloaded images
- Shared child listener cleanup when share is revoked

**Step 2: Create sync provider**

```dart
// lib/providers/sync_provider.dart
final syncServiceProvider = Provider((ref) {
  final isar = ref.watch(isarProvider).valueOrNull;
  final userId = ref.watch(currentUserIdProvider);
  if (isar == null || userId == null) return null;
  return FirestoreSyncService(isar: isar, userId: userId);
});
```

**Step 3: Commit**

```bash
git add lib/services/firestore_sync_service.dart lib/providers/sync_provider.dart
git commit -m "feat: add Firestore sync service with snapshot listeners"
```

---

### Task 12: Riverpod Data Providers

**Files:**
- Create: `little_artist_flutter/lib/providers/children_provider.dart`
- Create: `little_artist_flutter/lib/providers/artwork_provider.dart`

**Step 1: Create children provider**

```dart
// lib/providers/children_provider.dart
// Watch Isar children collection as a stream
// Provide: allChildren, childById, childCount
// Actions: addChild, updateChild, deleteChild (delegate to FirestoreRepository)
```

**Step 2: Create artwork provider**

```dart
// lib/providers/artwork_provider.dart
// Watch Isar artworks as streams, filtered by child/tag/search
// Provide: artworksByChild, allArtworks, artworkCount, favoriteArtworks
// Actions: addArtwork, updateArtwork, deleteArtwork, batchCreateArtworks
```

**Step 3: Commit**

```bash
git add lib/providers/
git commit -m "feat: add Riverpod providers for children and artworks"
```

---

## Phase 4: Core UI Components

### Task 13: Reusable Components — Avatars

**Files:**
- Create: `little_artist_flutter/lib/components/avatars/child_avatar_view.dart`
- Create: `little_artist_flutter/lib/components/avatars/child_slider_view.dart`

**Step 1: Create child avatar**

Port `ChildAvatarView.swift`:
- Circle with background color from `avatarColor` hex
- First letter of child's name centered
- Optional custom avatar image overlay
- Ring border when selected (Brand.avatarRingSize, Brand.avatarRingStroke)
- Brand.avatarShadow
- Size: Brand.avatarSize (60pt)

**Step 2: Create child slider**

Port `ChildSliderView.swift`:
- Horizontal scrollable row of `ChildAvatarView` widgets
- "All" chip at the start
- Selected state with primary color ring
- Tap callback with selected child

**Step 3: Commit**

```bash
git add lib/components/avatars/
git commit -m "feat: add child avatar and slider components"
```

---

### Task 14: Reusable Components — Cards

**Files:**
- Create: `little_artist_flutter/lib/components/cards/artwork_thumbnail_view.dart`
- Create: `little_artist_flutter/lib/components/cards/stat_card_view.dart`
- Create: `little_artist_flutter/lib/components/cards/timeline_entry_card_view.dart`
- Create: `little_artist_flutter/lib/components/cards/achievement_badge_view.dart`
- Create: `little_artist_flutter/lib/components/cards/memory_card_view.dart`

**Step 1: Create artwork thumbnail**

Port `ArtworkThumbnailView.swift`:
- Fixed size: Brand.thumbnailWidth x Brand.thumbnailHeight (164x180)
- Rounded corners: Brand.radiusCard (18)
- Image fills container with `BoxFit.cover`
- Title overlay at bottom with gradient scrim
- Favorite heart icon overlay top-right
- Brand.cardShadow
- Loading shimmer placeholder when no image

**Step 2: Create remaining card components**

Port each card from the iOS app:
- `StatCardView` — icon, value, label in a rounded card
- `TimelineEntryCardView` — artwork image + metadata for timeline
- `AchievementBadgeView` — icon with label in a circular badge
- `MemoryCardView` — "On this day" artwork card

**Step 3: Commit**

```bash
git add lib/components/cards/
git commit -m "feat: add card components (thumbnail, stat, timeline, achievement, memory)"
```

---

### Task 15: Reusable Components — Chips

**Files:**
- Create: `little_artist_flutter/lib/components/chips/child_filter_chip_view.dart`
- Create: `little_artist_flutter/lib/components/chips/year_chip_view.dart`
- Create: `little_artist_flutter/lib/components/chips/tag_chip_view.dart`
- Create: `little_artist_flutter/lib/components/chips/tag_picker_view.dart`

**Step 1: Create filter chips**

Port chip components:
- `ChildFilterChipView` — pill shape, avatar + name, selected = primary bg
- `YearChipView` — pill, year label, selected = primary bg
- `TagChipView` — pill, tag name, optional remove button
- `TagPickerView` — wrap of existing tags + text field to add new

All chips use `Capsule` shape equivalent (`StadiumBorder`), Brand tokens for colors.

**Step 2: Commit**

```bash
git add lib/components/chips/
git commit -m "feat: add chip components (child filter, year, tag)"
```

---

### Task 16: Reusable Components — Buttons

**Files:**
- Create: `little_artist_flutter/lib/components/buttons/add_artwork_button.dart`
- Create: `little_artist_flutter/lib/components/buttons/add_child_button.dart`

**Step 1: Create FAB and add-child button**

Port button components:
- `AddArtworkButton` — FAB, Brand.fabSize (60), primary color, plus icon, Brand.fabShadow
- `AddChildButton` — dashed circle button for adding a new child profile

**Step 2: Commit**

```bash
git add lib/components/buttons/
git commit -m "feat: add button components"
```

---

## Phase 5: Main Views

### Task 17: Home / Gallery View

**Files:**
- Create: `little_artist_flutter/lib/views/home_view.dart`
- Create: `little_artist_flutter/lib/views/artwork/artwork_gallery_view.dart`
- Create: `little_artist_flutter/lib/views/artwork/no_artwork_view.dart`

**Step 1: Create HomeView**

Port `HomeView.swift`:
- Top: child slider (ChildSliderView) for filtering
- "On This Day" memories section (MemoryCardView horizontal scroll)
- Artwork gallery grid (ArtworkGalleryView)
- FAB (AddArtworkButton) floating bottom-right
- Empty state (NoArtworkView) when no artworks

**Step 2: Create ArtworkGalleryView**

Port `ArtworkGalleryView.swift`:
- Grid of ArtworkThumbnailView widgets
- 2 columns on phone, responsive on tablet
- Lazy loading with `SliverGrid`
- Tap navigates to artwork detail

**Step 3: Create NoArtworkView**

Port `NoArtworkView.swift`:
- Illustration/icon placeholder
- "No artwork yet" message
- "Add your first artwork" CTA button

**Step 4: Wire up to GoRouter**

Replace placeholder `/gallery` route with `HomeView`.

**Step 5: Commit**

```bash
git add lib/views/home_view.dart lib/views/artwork/
git commit -m "feat: add home gallery view with artwork grid"
```

---

### Task 18: Child Management Views

**Files:**
- Create: `little_artist_flutter/lib/views/children/add_child_view.dart`
- Create: `little_artist_flutter/lib/views/children/edit_child_view.dart`
- Create: `little_artist_flutter/lib/views/children/no_children_view.dart`

**Step 1: Create AddChildView**

Port `AddChildView.swift`:
- Name text field
- Avatar color picker (horizontal row of color circles, Brand.avatarColors)
- Optional custom avatar photo (image_picker)
- Avatar preview (Brand.avatarPreviewSize)
- Save button — calls children provider to create
- Premium gate check (PremiumManager.canAddChild)

**Step 2: Create EditChildView**

Port `EditChildView.swift`:
- Same layout as AddChildView but pre-populated
- Update button
- Delete button with confirmation dialog

**Step 3: Create NoChildrenView**

Port `NoChildrenView.swift`:
- Empty state with illustration
- "Add your first child" CTA

**Step 4: Add routes**

Add GoRouter routes for `/children/add`, `/children/:id/edit`.

**Step 5: Commit**

```bash
git add lib/views/children/
git commit -m "feat: add child management views (add, edit, empty state)"
```

---

### Task 19: Add Artwork View

**Files:**
- Create: `little_artist_flutter/lib/views/artwork/add_artwork_view.dart`

**Step 1: Create AddArtworkView**

Port `AddArtworkView.swift` — this is the most complex view:

**Image source selection:**
- Camera (image_picker with camera source)
- Photo library (image_picker with gallery source)
- Document scanner (cunning_document_scanner)
- Three source buttons in a row (Brand.sourceButtonSize)

**Form fields:**
- Title text field
- Caption text field (multiline)
- Child selector (dropdown or chip row)
- Tag picker (TagPickerView)

**AI suggestions:**
- "Suggest" button triggers AI title/caption generation
- AI shimmer loading animation
- Accept/reject suggestion UI

**Voice memo (premium only):**
- Inline VoiceMemoRecorderView
- Premium gate with upsell

**Actions:**
- Save — validates, processes image, creates artwork via provider
- Cancel — confirms discard if changes made

**Step 2: Add route**

Add GoRouter route for `/artwork/add` with optional `childId` parameter.

**Step 3: Commit**

```bash
git add lib/views/artwork/add_artwork_view.dart
git commit -m "feat: add artwork creation view with camera, scanner, AI suggestions"
```

---

### Task 20: Artwork Detail View

**Files:**
- Create: `little_artist_flutter/lib/views/artwork/artwork_detail_view.dart`

**Step 1: Create ArtworkDetailView**

Port `ArtworkDetailView.swift`:
- Full-screen artwork image (pinch to zoom with InteractiveViewer)
- Title, caption, date, child name, tags
- Favorite toggle (heart icon)
- Edit button — opens edit mode (same form as add, pre-populated)
- Share button — share image via share_plus
- Delete button with confirmation
- Voice memo player (if voice note data exists)
- Navigation: back to gallery

**Step 2: Add route**

Add GoRouter route for `/artwork/:id`.

**Step 3: Commit**

```bash
git add lib/views/artwork/artwork_detail_view.dart
git commit -m "feat: add artwork detail view"
```

---

### Task 21: Timeline View

**Files:**
- Create: `little_artist_flutter/lib/views/timeline_view.dart`

**Step 1: Create TimelineView**

Port `TimelineView.swift`:
- Year filter chips at top (YearChipView horizontal scroll)
- Artworks grouped by month, sorted chronologically
- Sticky month headers (e.g., "March 2026")
- Timeline spine visualization (vertical line with dots)
- TimelineEntryCardView for each artwork
- Lazy loading with CustomScrollView + SliverList
- Expandable/collapsible month groups

**Step 2: Wire up route**

Replace placeholder `/timeline` with `TimelineView`.

**Step 3: Commit**

```bash
git add lib/views/timeline_view.dart
git commit -m "feat: add timeline view with month grouping"
```

---

### Task 22: Search View

**Files:**
- Create: `little_artist_flutter/lib/views/search_view.dart`

**Step 1: Create SearchView**

Port `SearchView.swift`:
- Search bar at top
- Full-text search across titles, captions, child names (Isar query)
- Filter by child, tags, favorites
- Tag cloud visualization
- Results grid (reuse ArtworkThumbnailView)
- Empty state when no results

**Step 2: Add to navigation**

Add search icon in app bar or as a fifth tab. The iOS app uses a search tab role — in Flutter, add a search action in the app bar that navigates to `/search`.

**Step 3: Commit**

```bash
git add lib/views/search_view.dart
git commit -m "feat: add search view with full-text search and filters"
```

---

### Task 23: Milestones View

**Files:**
- Create: `little_artist_flutter/lib/views/milestones_view.dart`

**Step 1: Create MilestonesView**

Port `MilestonesView.swift`:
- Stats section with StatCardView grid (total artworks, favorites, children, etc.)
- Achievement badges (AchievementBadgeView) — unlocked based on artwork count milestones
- Per-child stats breakdown
- Artwork streaks and "on this day" highlights

**Step 2: Wire up route**

Replace placeholder `/milestones` with `MilestonesView`.

**Step 3: Commit**

```bash
git add lib/views/milestones_view.dart
git commit -m "feat: add milestones view with stats and achievements"
```

---

### Task 24: Settings View

**Files:**
- Create: `little_artist_flutter/lib/views/settings_view.dart`

**Step 1: Create SettingsView**

Port `SettingsView.swift`:

**Children section:**
- List of children with edit/delete
- Add child button
- Share management per child (if premium)

**Preferences:**
- AI captions toggle
- Default camera (front/back) toggle
- Notifications toggle

**AI Usage:**
- Daily/weekly/monthly usage bars with limits (GeminiUsageTracker data)

**Subscription:**
- Current plan display
- Upgrade button -> PaywallView

**Data Management:**
- Storage used calculation
- Export as PDF button
- Delete account button with confirmation

**About:**
- App version
- Privacy policy link
- Open source licenses

**Step 2: Wire up route**

Replace placeholder `/settings` with `SettingsView`.

**Step 3: Commit**

```bash
git add lib/views/settings_view.dart
git commit -m "feat: add settings view"
```

---

## Phase 6: Premium & Monetization

### Task 25: Premium Manager & Store Manager

**Files:**
- Create: `little_artist_flutter/lib/services/premium_manager.dart`
- Create: `little_artist_flutter/lib/services/store_manager.dart`
- Create: `little_artist_flutter/lib/providers/premium_provider.dart`

**Step 1: Create PremiumManager**

Port `PremiumManager.swift`:
```dart
abstract final class PremiumManager {
  static const freeChildLimit = 2;
  static const freeArtworkLimit = 50;

  static bool get isPremium => // read from SharedPreferences

  static bool canAddChild(int currentCount) => isPremium || currentCount < freeChildLimit;
  static bool canAddArtwork(int currentCount) => isPremium || currentCount < freeArtworkLimit;
  static bool canShare() => isPremium;
}
```

**Step 2: Create StoreManager**

Port `StoreKitManager.swift` using `in_app_purchase`:
- Product IDs: `com.flutterly.littleartist.premium.monthly`, `.yearly`
- `loadProducts()` — fetch from store
- `purchase(ProductDetails)` — initiate purchase, verify
- `restorePurchases()` — restore prior purchases
- `listenForTransactions()` — stream of purchase updates
- Update `SharedPreferences["isPremium"]` on verified purchase

**Step 3: Create premium provider**

```dart
final isPremiumProvider = StateProvider<bool>((ref) {
  // Read from SharedPreferences, updated by StoreManager
});
```

**Step 4: Commit**

```bash
git add lib/services/premium_manager.dart lib/services/store_manager.dart lib/providers/premium_provider.dart
git commit -m "feat: add premium manager and in-app purchase service"
```

---

### Task 26: Paywall & Upsell Views

**Files:**
- Create: `little_artist_flutter/lib/views/paywall_view.dart`
- Create: `little_artist_flutter/lib/views/premium_upsell_view.dart`

**Step 1: Create PaywallView**

Port `PaywallView.swift`:
- Feature comparison matrix (free vs premium)
- Monthly and yearly subscription options with prices
- Purchase buttons
- Restore purchases link
- Terms and privacy links

**Step 2: Create PremiumUpsellView**

Port `PremiumUpsellView.swift`:
- Contextual upsell (triggered when hitting limits)
- Shows which limit was hit
- "Upgrade" CTA -> navigates to PaywallView

**Step 3: Commit**

```bash
git add lib/views/paywall_view.dart lib/views/premium_upsell_view.dart
git commit -m "feat: add paywall and premium upsell views"
```

---

## Phase 7: AI & Advanced Features

### Task 27: AI Suggestion Service

**Files:**
- Create: `little_artist_flutter/lib/services/ai_suggestion_service.dart`
- Create: `little_artist_flutter/lib/services/gemini_usage_tracker.dart`

**Step 1: Create GeminiUsageTracker**

Port `GeminiUsageTracker.swift`:
- Daily limit: 15, weekly: 60, monthly: 200
- Persist counters in SharedPreferences
- Automatic period rollover
- `canMakeRequest`, `recordRequest()`, `remainingRequests`, `usageSummary`

**Step 2: Create AISuggestionService**

Port `AISuggestionService.swift` using `firebase_vertexai`:
- `validateArtwork(Uint8List imageData)` — Gemini multimodal check if image is children's art
- `generateSuggestions(Uint8List imageData, String? childName)` — generate title + caption
- `improveSuggestions(imageData, existingTitle, existingCaption, childName)` — refine existing
- `parseSuggestions(String content)` — extract JSON or line-by-line from response
- Models priority: `gemini-2.5-flash`, `gemini-2.5-flash-lite`, `gemini-2.0-flash-001`
- Fallback defaults: "My Artwork", "A colorful creation..."
- Usage limit check before every call

**Step 3: Commit**

```bash
git add lib/services/ai_suggestion_service.dart lib/services/gemini_usage_tracker.dart
git commit -m "feat: add AI suggestion service with Gemini and usage tracking"
```

---

### Task 28: Voice Memo Components

**Files:**
- Create: `little_artist_flutter/lib/services/audio_recording_service.dart`
- Create: `little_artist_flutter/lib/components/voice_memo/voice_memo_recorder_view.dart`
- Create: `little_artist_flutter/lib/components/voice_memo/voice_memo_player_view.dart`
- Create: `little_artist_flutter/lib/components/voice_memo/waveform_animation_view.dart`
- Create: `little_artist_flutter/lib/components/voice_memo/playback_waveform_view.dart`

**Step 1: Create AudioRecordingService**

Port `AudioRecordingService.swift` using `record` + `just_audio`:
- AAC M4A format, 44.1kHz mono
- Max 30 seconds auto-stop
- Real-time level metering (50ms timer)
- `startRecording()`, `stopRecording() -> Uint8List?`, `cancelRecording()`
- `play(Uint8List data)`, `stopPlayback()`
- `extractAmplitudes(Uint8List, int sampleCount)` — waveform data
- Level history: 30-sample rolling buffer
- Published state: isRecording, isPlaying, recordingTime, currentLevel, levelHistory

**Step 2: Create voice memo UI components**

Port waveform and recorder/player views:
- `WaveformAnimationView` — animated bars during recording
- `PlaybackWaveformView` — static waveform with playback position
- `VoiceMemoRecorderView` — record button, timer, waveform, stop/cancel
- `VoiceMemoPlayerView` — play/pause button, waveform, duration

**Step 3: Commit**

```bash
git add lib/services/audio_recording_service.dart lib/components/voice_memo/
git commit -m "feat: add voice memo recording and playback with waveform"
```

---

### Task 29: Sharing Management

**Files:**
- Create: `little_artist_flutter/lib/views/children/share_management_view.dart`

**Step 1: Create ShareManagementView**

Port `ShareManagementView.swift`:
- Show share status (active/none)
- Create share button (generates share link/code)
- Participant list with roles
- Stop sharing / Leave share buttons
- Premium gate check

**Step 2: Add route**

Add GoRouter route for `/children/:id/share`.

**Step 3: Commit**

```bash
git add lib/views/children/share_management_view.dart
git commit -m "feat: add share management view"
```

---

### Task 30: PDF Export

**Files:**
- Create: `little_artist_flutter/lib/services/pdf_export_service.dart`

**Step 1: Create PDF export service**

Port `PDFExportService.swift` using the `pdf` dart package:
- `generatePortfolio(String childName, List<Artwork> artworks) -> Uint8List`
- Cover page: title, icon, artwork count, date
- One artwork per page: image (aspect-ratio preserved, max 480pt height), title, date, caption
- US Letter format (612x792pt), 50pt margins
- Brand colors for headers and accents
- Share via `share_plus` or `printing` package

**Step 2: Commit**

```bash
git add lib/services/pdf_export_service.dart
git commit -m "feat: add PDF portfolio export service"
```

---

### Task 31: Notifications

**Files:**
- Create: `little_artist_flutter/lib/services/notification_service.dart`

**Step 1: Create notification service**

Port `NotificationService.swift` using `flutter_local_notifications`:
- `requestPermission()` — request notification auth
- `scheduleAll(List<Artwork>)` — cancel all, reschedule
- `scheduleInactivityReminder(DateTime lastArtworkDate)` — 14 days after last artwork
- `scheduleOnThisDayNotifications(List<Artwork>)` — daily 9 AM for same month/day in prior years
- Platform-specific setup (Android channel, iOS categories)

**Step 2: Commit**

```bash
git add lib/services/notification_service.dart
git commit -m "feat: add local notification service"
```

---

### Task 32: Haptic Service

**Files:**
- Create: `little_artist_flutter/lib/services/haptic_service.dart`

**Step 1: Create haptic service**

Port `HapticService.swift`:
```dart
import 'package:flutter/services.dart';

abstract final class HapticService {
  static void selection() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void success() => HapticFeedback.heavyImpact();
  static void warning() => HapticFeedback.vibrate();
}
```

**Step 2: Commit**

```bash
git add lib/services/haptic_service.dart
git commit -m "feat: add haptic feedback service"
```

---

## Phase 8: Onboarding

### Task 33: Onboarding Flow

**Files:**
- Create: `little_artist_flutter/lib/views/onboarding/onboarding_view.dart`
- Create: `little_artist_flutter/lib/views/onboarding/animated_cards_view.dart`
- Create: `little_artist_flutter/lib/views/onboarding/fan_cards_view.dart`
- Create: `little_artist_flutter/lib/views/onboarding/drop_cards_view.dart`
- Create: `little_artist_flutter/lib/views/onboarding/pulse_cards_view.dart`
- Create: `little_artist_flutter/lib/views/onboarding/scatter_cards_view.dart`
- Create: `little_artist_flutter/lib/views/onboarding/drift_cards_view.dart`
- Create: `little_artist_flutter/lib/views/splash_view.dart`

**Step 1: Create card animation views**

Port each animation from iOS using Flutter `AnimationController` + `Tween`:
- `FanCardsView` — cards fan out from center
- `DropCardsView` — cards drop in from above with stagger
- `PulseCardsView` — cards pulse/scale rhythmically
- `ScatterCardsView` — cards scatter to random positions
- `DriftCardsView` — cards drift slowly across screen

Each animation view:
- Uses `StatefulWidget` with `TickerProviderStateMixin`
- `AnimationController` for timing
- `Transform` widgets for position/rotation/scale
- Brand.onboardingCardHeight for card sizing
- Staggered delays between cards

**Step 2: Create AnimatedCardsView**

Port `AnimatedCardsView.swift`:
- Cycles through animation types based on page index
- Icon cards with SF Symbol equivalents (Material Icons)

**Step 3: Create OnboardingView**

Port `OnboardingView.swift`:
- PageView with 3-4 onboarding pages
- Each page: animated cards background, headline, description
- Page indicator dots
- "Continue" button advances pages
- Final page: Sign in with Apple button + "Skip" to anonymous auth
- On completion: set `hasCompletedOnboarding = true` in SharedPreferences
- Navigate to ContentView

**Step 4: Create SplashView**

Port `SplashVideoView.swift`:
- App logo/animation on Brand.cream background
- Brief delay then transition to onboarding or content view
- Check `hasCompletedOnboarding` to decide routing

**Step 5: Update GoRouter**

Add initial route logic:
- If `!hasCompletedOnboarding` -> `/onboarding`
- Else -> `/gallery`

**Step 6: Commit**

```bash
git add lib/views/onboarding/ lib/views/splash_view.dart
git commit -m "feat: add onboarding flow with card animations"
```

---

## Phase 9: Remaining Components & Polish

### Task 34: AI Shimmer & Confetti

**Files:**
- Create: `little_artist_flutter/lib/components/ai_shimmer_view.dart`
- Create: `little_artist_flutter/lib/components/confetti_view.dart`

**Step 1: Create AIShimmerView**

Port `AIShimmerView.swift`:
- Animated gradient shimmer effect for AI loading states
- Linear gradient that slides horizontally
- Brand.primary and Brand.primaryTint colors

**Step 2: Create ConfettiView**

Port `ConfettiView.swift`:
- Particle animation for celebrations (achievement unlocked, first artwork)
- Random colors from Brand palette
- Gravity-affected particles

**Step 3: Commit**

```bash
git add lib/components/ai_shimmer_view.dart lib/components/confetti_view.dart
git commit -m "feat: add AI shimmer and confetti animations"
```

---

### Task 35: Artwork Comparison View

**Files:**
- Create: `little_artist_flutter/lib/views/artwork/artwork_comparison_view.dart`

**Step 1: Create ArtworkComparisonView**

Port `ArtworkComparisonView.swift`:
- Side-by-side before/after view
- Slider to reveal/hide comparison
- Used for viewing artwork edits

**Step 2: Add route**

Add GoRouter route for `/artwork/:id/compare`.

**Step 3: Commit**

```bash
git add lib/views/artwork/artwork_comparison_view.dart
git commit -m "feat: add artwork comparison view"
```

---

### Task 36: Privacy Policy & Shared Badge

**Files:**
- Create: `little_artist_flutter/lib/views/privacy_policy_view.dart`
- Create: `little_artist_flutter/lib/components/badges/shared_badge_view.dart`

**Step 1: Create PrivacyPolicyView**

Port `PrivacyPolicyView.swift`:
- WebView or scrollable text with privacy policy content
- Accessible from Settings

**Step 2: Create SharedBadgeView**

Port `SharedBadgeView.swift`:
- Small badge indicator showing shared status on child avatars/cards
- Icon + "Shared" label

**Step 3: Commit**

```bash
git add lib/views/privacy_policy_view.dart lib/components/badges/
git commit -m "feat: add privacy policy view and shared badge"
```

---

## Phase 10: Integration & Polish

### Task 37: Complete Route Wiring

**Files:**
- Modify: `little_artist_flutter/lib/app.dart`

**Step 1: Wire all routes**

Update GoRouter with complete route tree:
```
/                       -> redirect to /gallery or /onboarding
/onboarding             -> OnboardingView
/gallery                -> HomeView
/gallery/artwork/add    -> AddArtworkView
/gallery/artwork/:id    -> ArtworkDetailView
/gallery/artwork/:id/compare -> ArtworkComparisonView
/timeline               -> TimelineView
/milestones             -> MilestonesView
/settings               -> SettingsView
/settings/children/add  -> AddChildView
/settings/children/:id/edit -> EditChildView
/settings/children/:id/share -> ShareManagementView
/settings/paywall       -> PaywallView
/settings/privacy       -> PrivacyPolicyView
/search                 -> SearchView
/share/:shareId         -> Deep link handler for share acceptance
```

**Step 2: Add auth guard**

GoRouter redirect: if no authenticated user, wait for anonymous sign-in.

**Step 3: Commit**

```bash
git add lib/app.dart
git commit -m "feat: wire complete route tree with auth guard"
```

---

### Task 38: App Lifecycle & Sync Integration

**Files:**
- Modify: `little_artist_flutter/lib/main.dart`
- Modify: `little_artist_flutter/lib/app.dart`

**Step 1: Initialize all services at startup**

Update `main.dart` startup sequence to match iOS:
1. `Firebase.initializeApp()`
2. Open Isar database
3. Initialize FirebaseAuthService (anonymous sign-in)
4. Wait for userId
5. If premium: upload all local data to Firestore
6. Start FirestoreSyncService listeners
7. Schedule notifications

**Step 2: Handle app lifecycle**

- Resume: restart sync listeners
- Pause: no action needed (Firestore handles offline queue)
- Detach: stop listeners

**Step 3: Commit**

```bash
git add lib/main.dart lib/app.dart
git commit -m "feat: integrate lifecycle management and sync startup"
```

---

### Task 39: Platform Configuration

**Files:**
- Modify: `little_artist_flutter/android/app/build.gradle`
- Modify: `little_artist_flutter/ios/Runner/Info.plist`

**Step 1: Android configuration**

- Min SDK: 24 (for Firebase + in_app_purchase)
- Camera/microphone/storage permissions in AndroidManifest.xml
- Notification channel setup
- Google Services plugin

**Step 2: iOS configuration**

- NSCameraUsageDescription
- NSMicrophoneUsageDescription
- NSPhotoLibraryUsageDescription
- Sign in with Apple capability
- In-App Purchase capability
- Push Notification capability
- Background Modes (for notifications)

**Step 3: Commit**

```bash
git add android/ ios/
git commit -m "feat: configure platform permissions and capabilities"
```

---

### Task 40: Build Verification

**Step 1: Run Flutter analyze**

```bash
cd "/Users/anoopjose/Projects/Little Artist/little_artist_flutter"
flutter analyze
```

Fix any warnings or errors.

**Step 2: Build Android debug**

```bash
flutter build apk --debug
```

**Step 3: Build iOS debug**

```bash
flutter build ios --debug --no-codesign
```

**Step 4: Run on simulator/emulator**

```bash
flutter run
```

Verify:
- App launches to splash/onboarding
- Tab navigation works
- Theme and brand tokens render correctly
- Firebase connection works (check anonymous auth)

**Step 5: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve build issues and verify cross-platform builds"
```

---

## Execution Order Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1 | 1-4 | Project scaffold, Firebase, tokens, shell |
| 2 | 5-6 | Isar models and database provider |
| 3 | 7-12 | Core services (auth, storage, Firestore, sync, providers) |
| 4 | 13-16 | Reusable UI components (avatars, cards, chips, buttons) |
| 5 | 17-24 | Main views (home, children, artwork, timeline, search, milestones, settings) |
| 6 | 25-26 | Premium & IAP |
| 7 | 27-32 | AI, voice memos, sharing, PDF, notifications, haptics |
| 8 | 33 | Onboarding with animations |
| 9 | 34-36 | Remaining components & polish |
| 10 | 37-40 | Integration, routing, lifecycle, build verification |

**Dependencies:** Phase 2 before Phase 3. Phase 3 before Phase 5. Phase 4 can run in parallel with Phase 3. Phases 6-9 depend on Phase 5. Phase 10 is last.
