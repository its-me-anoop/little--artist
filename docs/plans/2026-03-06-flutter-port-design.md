# Little Artist Flutter Port — Design Document

**Date:** 2026-03-06
**Status:** Approved

## Overview

Cross-platform (Android + iOS) Flutter app that replicates the existing native iOS "Little Artist" app feature-for-feature. Shares the same Firebase backend (Auth, Firestore, Storage) so both apps can access the same data. Lives in `little_artist_flutter/` subdirectory of the existing repo.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Backend | Same Firebase project | Shared data between iOS and Flutter |
| Platforms | Android + iOS | Full cross-platform |
| Local persistence | Isar | Offline-first, fast NoSQL, complex queries |
| AI suggestions | Firebase Vertex AI SDK | Mirrors iOS approach, client-side Gemini |
| In-app purchases | `in_app_purchase` plugin | Official Flutter plugin, no third-party dependency |
| Onboarding animations | Custom Flutter animations | `AnimationController` / `Tween` to match iOS feel |
| Project location | `little_artist_flutter/` subdirectory | Alongside existing iOS project |

## Architecture

### State Management
Riverpod — clean dependency injection, reactive streams from Firestore, testable providers.

### Local Persistence
Isar — fast NoSQL database. Dual-write pattern mirrors iOS:
1. Write to Isar (instant UI update via Riverpod)
2. Async write to Firestore
3. Binary upload to Firebase Storage
4. Firestore snapshot listener reconciles remote changes into Isar (echo suppression for local writes)

### Navigation
GoRouter — declarative routing, deep link support for share acceptance (`/share/{shareId}`).

## Project Structure

```
little_artist_flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                       # MaterialApp + GoRouter
│   ├── models/
│   │   ├── child.dart
│   │   ├── artwork.dart
│   │   └── tag.dart
│   ├── services/
│   │   ├── firebase_auth_service.dart
│   │   ├── firestore_repository.dart
│   │   ├── firestore_sync_service.dart
│   │   ├── ai_suggestion_service.dart
│   │   ├── gemini_usage_tracker.dart
│   │   ├── store_manager.dart
│   │   ├── premium_manager.dart
│   │   ├── storage_service.dart
│   │   ├── image_processing_service.dart
│   │   ├── audio_recording_service.dart
│   │   ├── pdf_export_service.dart
│   │   ├── notification_service.dart
│   │   └── haptic_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── children_provider.dart
│   │   ├── artwork_provider.dart
│   │   ├── premium_provider.dart
│   │   └── sync_provider.dart
│   ├── views/
│   │   ├── home_view.dart
│   │   ├── timeline_view.dart
│   │   ├── search_view.dart
│   │   ├── settings_view.dart
│   │   ├── milestones_view.dart
│   │   ├── paywall_view.dart
│   │   ├── premium_upsell_view.dart
│   │   ├── splash_view.dart
│   │   ├── privacy_policy_view.dart
│   │   ├── onboarding/
│   │   │   ├── onboarding_view.dart
│   │   │   ├── animated_cards_view.dart
│   │   │   ├── fan_cards_view.dart
│   │   │   ├── drop_cards_view.dart
│   │   │   ├── pulse_cards_view.dart
│   │   │   ├── scatter_cards_view.dart
│   │   │   └── drift_cards_view.dart
│   │   ├── artwork/
│   │   │   ├── add_artwork_view.dart
│   │   │   ├── artwork_detail_view.dart
│   │   │   ├── artwork_gallery_view.dart
│   │   │   ├── artwork_comparison_view.dart
│   │   │   └── no_artwork_view.dart
│   │   └── children/
│   │       ├── add_child_view.dart
│   │       ├── edit_child_view.dart
│   │       ├── share_management_view.dart
│   │       └── no_children_view.dart
│   ├── components/
│   │   ├── ai_shimmer_view.dart
│   │   ├── confetti_view.dart
│   │   ├── buttons/
│   │   │   ├── add_artwork_button.dart
│   │   │   └── add_child_button.dart
│   │   ├── cards/
│   │   │   ├── artwork_thumbnail_view.dart
│   │   │   ├── stat_card_view.dart
│   │   │   ├── achievement_badge_view.dart
│   │   │   ├── timeline_entry_card_view.dart
│   │   │   └── memory_card_view.dart
│   │   ├── chips/
│   │   │   ├── child_filter_chip_view.dart
│   │   │   ├── year_chip_view.dart
│   │   │   ├── tag_chip_view.dart
│   │   │   └── tag_picker_view.dart
│   │   ├── avatars/
│   │   │   ├── child_avatar_view.dart
│   │   │   └── child_slider_view.dart
│   │   ├── badges/
│   │   │   └── shared_badge_view.dart
│   │   └── voice_memo/
│   │       ├── voice_memo_recorder_view.dart
│   │       ├── voice_memo_player_view.dart
│   │       ├── playback_waveform_view.dart
│   │       └── waveform_animation_view.dart
│   └── utils/
│       ├── brand_tokens.dart
│       ├── color_hex.dart
│       └── constants.dart
├── assets/
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

## Key Packages

| Concern | Package |
|---------|---------|
| State management | `flutter_riverpod` |
| Local DB | `isar`, `isar_flutter_libs` |
| Routing | `go_router` |
| Firebase core | `firebase_core` |
| Auth | `firebase_auth`, `sign_in_with_apple`, `google_sign_in` |
| Firestore | `cloud_firestore` |
| Storage | `firebase_storage` |
| AI | `firebase_vertexai` |
| IAP | `in_app_purchase` |
| Camera/Photos | `image_picker` |
| Scanner | `cunning_document_scanner` |
| Audio recording | `record` |
| Audio playback | `just_audio` |
| PDF generation | `pdf` |
| Notifications | `flutter_local_notifications` |
| Image compression | `flutter_image_compress` |
| Fonts | `google_fonts` |
| Haptics | `flutter/services.dart` (HapticFeedback) |
| Path | `path_provider` |
| Permissions | `permission_handler` |
| Share/export | `share_plus` |
| URL launcher | `url_launcher` |

## Data Models (Isar)

### Child
```dart
@collection
class Child {
  Id id = Isar.autoIncrement;
  String name;
  String avatarColor; // hex
  DateTime createdAt;
  byte[]? avatarImageData;
  String? firestoreId;
  bool isShared;
  String? ownerUserId;
  // Link to artworks via IsarLinks
}
```

### Artwork
```dart
@collection
class Artwork {
  Id id = Isar.autoIncrement;
  String title;
  String caption;
  byte[]? imageData;
  byte[]? thumbnailData;
  byte[]? voiceNoteData;
  bool isFavorited;
  DateTime createdAt;
  String? firestoreId;
  String? imageURL;
  String? voiceNoteURL;
  // Link to child, tags via IsarLinks
}
```

### Tag
```dart
@collection
class Tag {
  Id id = Isar.autoIncrement;
  String name;
  // Backlink to artworks
}
```

## Data Flow

### Dual-Write Pattern
```
User Action
  -> Write to Isar (instant UI update via Riverpod stream)
  -> Async write to Firestore (queued offline)
  -> Binary upload to Firebase Storage (retry 3x)

Firestore snapshot listener
  -> Skip local writes (echo suppression via localWriteIds set)
  -> Reconcile into Isar
  -> Riverpod streams notify UI automatically
```

### Sync Service
- Snapshot listeners on children collection and artwork subcollections
- Echo write suppression using local write ID tracking
- One-time deduplication pass after initial children snapshot
- Shared child tracking via shares collection listener
- Thumbnail generation for downloaded images

## Design System

Direct port of `BrandTokens.swift` to `brand_tokens.dart`:

### Colors
| Token | Hex | Usage |
|-------|-----|-------|
| primary | `#F2784B` | CTAs, selected states, FAB |
| primaryTint | `#F2784B` at 12% | Badge backgrounds |
| cream | `#FFF8F0` | App background |
| surface | `#FFFBF7` | Cards, sheets |
| charcoal | `#3D3D3D` | Headings, body text |
| warmGray | `#8A8680` | Subtitles, hints |
| softTan | `#E8E0D8` | Dividers, borders |
| sage | `#A8C5A0` | Success states |
| sky | `#7EB8DA` | Informational |
| lavender | `#B8A9D4` | Tertiary accent |
| dustyRose | `#D4736C` | Destructive actions |

### Typography
- Headings: Google Fonts `Nunito` (rounded, similar to SF Rounded)
- Body: System default (Roboto on Android, SF Pro on iOS)
- Same size scale as iOS (32/28/22/20/17/15/12pt)

### Spacing, Radii, Shadows
Identical values to iOS BrandTokens — all centralized in `brand_tokens.dart`.

### Icons
Material Icons + Cupertino Icons as SF Symbols replacements. Map key icons:
- `paintpalette.fill` -> `Icons.palette`
- `camera.fill` -> `Icons.camera_alt`
- `photo.on.rectangle` -> `Icons.photo_library`
- `sparkles` -> `Icons.auto_awesome`
- `plus` -> `Icons.add`
- `xmark.circle.fill` -> `Icons.cancel`

## Feature Parity

### Core Features
- Onboarding with card animations (fan, drop, pulse, scatter, drift)
- Anonymous auth + Sign in with Apple
- Child CRUD with avatar colors and custom photos
- Artwork CRUD (camera, photo picker, document scanner)
- AI-powered title/caption suggestions (Gemini)
- Artwork validation (is it children's art?)
- Gallery view with thumbnails, child/tag filtering
- Timeline view grouped by month with year chips
- Search with full-text across titles, captions, child names
- Milestones and achievements
- Voice memo recording/playback with waveform visualization
- Premium subscriptions (monthly/yearly)
- Free tier limits (2 children, 50 artworks)
- Family sharing via Firestore
- PDF export
- Local notifications (inactivity reminders, "on this day" memories)
- Offline-first with cloud sync
- Haptic feedback
- Splash screen with video

### Premium Gating
Same limits as iOS:
- Free: 2 children, 50 artworks, no voice memos, no sharing, no cloud sync
- Premium: unlimited children/artworks, voice memos, sharing, cloud sync

## What Changes from iOS

| iOS | Flutter |
|-----|---------|
| SwiftData | Isar |
| StoreKit 2 | `in_app_purchase` |
| SF Symbols | Material Icons + Cupertino Icons |
| UIKit bridges (Camera, Scanner) | Flutter plugins |
| SF Rounded | Google Fonts Nunito |
| SwiftUI animations | `AnimationController` + `Tween` |
| `@State` / `@Binding` / `@Query` | Riverpod providers |
| NavigationStack | GoRouter |
| `@AppStorage` | `SharedPreferences` |
