# Image Compression & Thumbnail Generation

**Date:** 2026-02-21
**Status:** Approved

## Problem

Artwork images are stored and uploaded uncompressed. A 12MP iPhone photo (4–8 MB) passes through as-is to SwiftData and Firebase Storage. Gallery views load full-resolution images for 164×180pt thumbnail cards. This causes slow scrolling, high memory usage, and excessive Firebase Storage costs.

## Decision

Inline processing at ingest time using a two-tier approach:

- **Main image:** Max 2048px longest edge, JPEG 0.7 quality (~200–400 KB)
- **Thumbnail:** Max 512px longest edge, JPEG 0.6 quality (~30–60 KB)

Original is discarded. Existing artworks are not migrated — views fall back to `imageData` when `thumbnailData` is nil.

## Architecture

### New Service

`Services/ImageProcessingService.swift` — stateless utility with two static entry points:

```swift
static func processForStorage(image: UIImage) -> (imageData: Data, thumbnailData: Data)
static func processForStorage(data: Data) -> (imageData: Data, thumbnailData: Data)?
```

Uses `UIGraphicsImageRenderer` for efficient resizing. No intermediate copies.

### Model Change

Add to `Artwork`:

```swift
@Attribute(.externalStorage)
var thumbnailData: Data?
```

New artworks receive both `imageData` (compressed main) and `thumbnailData`. Existing artworks have `thumbnailData = nil`.

### Ingest Points

Four image entry points in `AddArtworkView.swift`:

| Source | Current | After |
|--------|---------|-------|
| Camera | `jpegData(0.85)` | `processForStorage(image:)` |
| Scanner | `jpegData(0.85)` | `processForStorage(image:)` |
| Photo picker | Raw `Data` | `processForStorage(data:)` |
| Batch import | Raw `Data` | `processForStorage(data:)` |

Avatar images unchanged — already small.

### View Changes

Gallery and card views use `thumbnailData` with fallback:

```swift
if let data = artwork.thumbnailData ?? artwork.imageData,
   let uiImage = UIImage(data: data)
```

**Switch to thumbnails:** `ArtworkThumbnailView`, `TimelineEntryCardView`, `MemoryCardView`, `ArtworkGalleryView` grid cells, `ArtworkComparisonView` picker.

**Keep full image:** `ArtworkDetailView`, `PDFExportService`, `AISuggestionService`.

### Firebase

No changes to `StorageService` or upload paths. Since `imageData` is now compressed at ingest, uploads are automatically ~200–400 KB instead of 4–8 MB. Thumbnails are not uploaded — recipients generate locally.

## Size Impact

| Metric | Before | After |
|--------|--------|-------|
| Single 12MP photo | 4–8 MB | ~250 KB + ~40 KB thumb |
| 100 artworks locally | 400–800 MB | ~29 MB |
| Firebase upload/artwork | 4–8 MB | ~250 KB |
| Gallery scroll memory | Full images | ~40 KB thumbnails |
