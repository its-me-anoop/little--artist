# Image Compression & Thumbnail Generation — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Compress artwork images on ingest and generate thumbnails for fast gallery scrolling and reduced Firebase Storage costs.

**Architecture:** A stateless `ImageProcessingService` processes images at all four ingest points (camera, scanner, photo picker, batch import). The `Artwork` model gains a `thumbnailData` property. Gallery/card views use thumbnails with fallback to full image for existing data.

**Tech Stack:** UIKit (`UIGraphicsImageRenderer`), SwiftData, SwiftUI

---

### Task 1: Create ImageProcessingService

**Files:**
- Create: `Little Artist/Services/ImageProcessingService.swift`

**Step 1: Create the service file**

```swift
//
//  ImageProcessingService.swift
//  Little Artist
//
//  Resizes and compresses artwork images at ingest time.
//  Produces a two-tier output: a main image (max 2048px, JPEG 0.7)
//  and a thumbnail (max 512px, JPEG 0.6).
//

import UIKit

/// Stateless image processing utility for artwork ingest.
///
/// Call ``processForStorage(image:)`` from camera/scanner captures, or
/// ``processForStorage(data:)`` from photo picker / batch imports.
enum ImageProcessingService {

    // MARK: - Configuration

    /// Maximum longest-edge dimension for the main stored image.
    static let mainMaxDimension: CGFloat = 2048

    /// JPEG compression quality for the main image (0.0–1.0).
    static let mainQuality: CGFloat = 0.7

    /// Maximum longest-edge dimension for the thumbnail.
    static let thumbnailMaxDimension: CGFloat = 512

    /// JPEG compression quality for the thumbnail (0.0–1.0).
    static let thumbnailQuality: CGFloat = 0.6

    // MARK: - Public API

    /// Processes a `UIImage` (from camera or scanner) into compressed main + thumbnail data.
    static func processForStorage(image: UIImage) -> (imageData: Data, thumbnailData: Data) {
        let mainImage = resized(image, maxDimension: mainMaxDimension)
        let thumbImage = resized(image, maxDimension: thumbnailMaxDimension)

        let imageData = mainImage.jpegData(compressionQuality: mainQuality) ?? Data()
        let thumbnailData = thumbImage.jpegData(compressionQuality: thumbnailQuality) ?? Data()

        return (imageData: imageData, thumbnailData: thumbnailData)
    }

    /// Processes raw `Data` (from photo picker) into compressed main + thumbnail data.
    /// Returns `nil` if the data cannot be decoded as an image.
    static func processForStorage(data: Data) -> (imageData: Data, thumbnailData: Data)? {
        guard let image = UIImage(data: data) else { return nil }
        return processForStorage(image: image)
    }

    /// Generates only a thumbnail from existing image data.
    /// Used when downloading shared artwork from Firebase (main image already stored).
    static func generateThumbnail(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let thumb = resized(image, maxDimension: thumbnailMaxDimension)
        return thumb.jpegData(compressionQuality: thumbnailQuality)
    }

    // MARK: - Private

    /// Resizes an image so its longest edge is at most `maxDimension`.
    /// Returns the original image if it's already smaller.
    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)

        guard longest > maxDimension else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(
            width: (size.width * scale).rounded(.down),
            height: (size.height * scale).rounded(.down)
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
```

**Step 2: Build to verify**

Run: `xcodebuild -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 17 Pro" build 2>&1 | grep -E "error:|BUILD"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Services/ImageProcessingService.swift"
git commit -m "feat: add ImageProcessingService for artwork compression and thumbnails"
```

---

### Task 2: Add thumbnailData to Artwork Model

**Files:**
- Modify: `Little Artist/Models/Artwork.swift`

**Step 1: Add the property after `imageData`**

After line 27 (`var imageData: Data?`), add:

```swift
    /// A smaller version of the artwork image for gallery/card views.
    /// Generated at ingest time. `nil` for artworks created before this feature.
    @Attribute(.externalStorage)
    var thumbnailData: Data?
```

**Step 2: Add parameter to init**

Add `thumbnailData: Data? = nil` parameter after `imageData` in the init, and add `self.thumbnailData = thumbnailData` in the body.

**Step 3: Build to verify**

Run: `xcodebuild ... build`
Expected: BUILD SUCCEEDED (SwiftData handles lightweight migration automatically for new optional properties)

**Step 4: Commit**

```bash
git add "Little Artist/Models/Artwork.swift"
git commit -m "feat: add thumbnailData property to Artwork model"
```

---

### Task 3: Update Camera and Scanner Ingest

**Files:**
- Modify: `Little Artist/Views/Artwork/AddArtworkView.swift`

**Step 1: Add a thumbnailData state variable**

Near the other `@State` declarations at the top of `AddArtworkView`, add:

```swift
@State private var capturedThumbnailData: Data?
```

**Step 2: Update camera capture (line ~242)**

Replace:
```swift
CameraPicker { image in
    if let data = image.jpegData(compressionQuality: 0.85) {
        capturedImageData = data
        suggestionErrorMessage = nil
    }
}
```

With:
```swift
CameraPicker { image in
    let processed = ImageProcessingService.processForStorage(image: image)
    capturedImageData = processed.imageData
    capturedThumbnailData = processed.thumbnailData
    suggestionErrorMessage = nil
}
```

**Step 3: Update scanner capture (line ~251)**

Replace:
```swift
DocumentScannerPicker { image in
    if let data = image.jpegData(compressionQuality: 0.85) {
        capturedImageData = data
        suggestionErrorMessage = nil
    }
}
```

With:
```swift
DocumentScannerPicker { image in
    let processed = ImageProcessingService.processForStorage(image: image)
    capturedImageData = processed.imageData
    capturedThumbnailData = processed.thumbnailData
    suggestionErrorMessage = nil
}
```

**Step 4: Update photo picker (line ~261)**

Replace:
```swift
if let data = try? await newItem.loadTransferable(type: Data.self) {
    capturedImageData = data
    suggestionErrorMessage = nil
}
```

With:
```swift
if let rawData = try? await newItem.loadTransferable(type: Data.self),
   let processed = ImageProcessingService.processForStorage(data: rawData) {
    capturedImageData = processed.imageData
    capturedThumbnailData = processed.thumbnailData
    suggestionErrorMessage = nil
}
```

**Step 5: Build to verify**

Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add "Little Artist/Views/Artwork/AddArtworkView.swift"
git commit -m "feat: compress camera, scanner, and photo picker images on capture"
```

---

### Task 4: Update Save and Batch Import to Pass Thumbnail

**Files:**
- Modify: `Little Artist/Views/Artwork/AddArtworkView.swift`
- Modify: `Little Artist/Services/FirestoreRepository.swift`
- Modify: `Little Artist/Models/Artwork.swift` (init already updated in Task 2)

**Step 1: Add `thumbnailData` parameter to `createArtwork` in FirestoreRepository**

In `FirestoreRepository.createArtwork()`, add `thumbnailData: Data? = nil` parameter. Pass it through to the `Artwork` init:

```swift
func createArtwork(
    title: String,
    caption: String = "",
    imageData: Data? = nil,
    thumbnailData: Data? = nil,    // NEW
    voiceNoteData: Data? = nil,
    ...
) -> Artwork {
    let artwork = Artwork(
        title: title,
        caption: caption,
        imageData: imageData,
        thumbnailData: thumbnailData,    // NEW
        voiceNoteData: voiceNoteData,
        ...
    )
```

**Step 2: Update `saveArtwork()` in AddArtworkView (~line 422)**

Pass `capturedThumbnailData`:

```swift
FirestoreRepository.shared.createArtwork(
    title: title.trimmingCharacters(in: .whitespaces),
    caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
    imageData: capturedImageData,
    thumbnailData: capturedThumbnailData,    // NEW
    voiceNoteData: voiceNoteData,
    createdAt: artworkDate,
    child: child,
    tags: selectedTags,
    in: modelContext
)
```

**Step 3: Update `batchImport()` in AddArtworkView (~line 404)**

Replace:
```swift
guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
repo.createArtwork(
    title: "",
    imageData: data,
    ...
)
```

With:
```swift
guard let rawData = try? await item.loadTransferable(type: Data.self),
      let processed = ImageProcessingService.processForStorage(data: rawData) else { continue }
repo.createArtwork(
    title: "",
    imageData: processed.imageData,
    thumbnailData: processed.thumbnailData,
    ...
)
```

**Step 4: Build to verify**

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add "Little Artist/Views/Artwork/AddArtworkView.swift" "Little Artist/Services/FirestoreRepository.swift"
git commit -m "feat: pass compressed images and thumbnails through save and batch import"
```

---

### Task 5: Generate Thumbnails on Firebase Download

**Files:**
- Modify: `Little Artist/Services/FirestoreSyncService.swift`

**Step 1: After image download, generate thumbnail (~line 430-433)**

Replace:
```swift
if let imgURL = imageURL, targetArtwork?.imageData == nil {
    if let imgData = await storage.download(url: imgURL) {
        targetArtwork?.imageData = imgData
    }
}
```

With:
```swift
if let imgURL = imageURL, targetArtwork?.imageData == nil {
    if let imgData = await storage.download(url: imgURL) {
        targetArtwork?.imageData = imgData
        // Generate thumbnail from downloaded image
        if targetArtwork?.thumbnailData == nil {
            targetArtwork?.thumbnailData = ImageProcessingService.generateThumbnail(from: imgData)
        }
    }
}
```

**Step 2: Build to verify**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add "Little Artist/Services/FirestoreSyncService.swift"
git commit -m "feat: generate thumbnails when downloading shared artwork from Firebase"
```

---

### Task 6: Update Gallery and Card Views to Use Thumbnails

**Files:**
- Modify: `Little Artist/Components/Cards/ArtworkThumbnailView.swift:32`
- Modify: `Little Artist/Components/Cards/TimelineEntryCardView.swift:23`
- Modify: `Little Artist/Components/Cards/MemoryCardView.swift:19`
- Modify: `Little Artist/Views/Artwork/ArtworkGalleryView.swift:270,360`
- Modify: `Little Artist/Views/Artwork/ArtworkComparisonView.swift:105,239`

**Step 1: ArtworkThumbnailView (line 32)**

Replace:
```swift
if let data = artwork.imageData, let uiImage = UIImage(data: data) {
```
With:
```swift
if let data = artwork.thumbnailData ?? artwork.imageData, let uiImage = UIImage(data: data) {
```

**Step 2: TimelineEntryCardView (line 23)**

Replace:
```swift
if let data = artwork.imageData, let uiImage = UIImage(data: data) {
```
With:
```swift
if let data = artwork.thumbnailData ?? artwork.imageData, let uiImage = UIImage(data: data) {
```

**Step 3: MemoryCardView (line 19)**

Replace:
```swift
if let imageData = artwork.imageData, let uiImage = UIImage(data: imageData) {
```
With:
```swift
if let imageData = artwork.thumbnailData ?? artwork.imageData, let uiImage = UIImage(data: imageData) {
```

**Step 4: ArtworkGalleryView grid cell (line 360)**

Replace:
```swift
if let data = artwork.imageData, let uiImage = UIImage(data: data) {
```
With:
```swift
if let data = artwork.thumbnailData ?? artwork.imageData, let uiImage = UIImage(data: data) {
```

**Step 5: ArtworkComparisonView slot image (line 105)**

Replace:
```swift
if let artwork, let data = artwork.imageData,
   let uiImage = UIImage(data: data) {
```
With:
```swift
if let artwork, let data = artwork.thumbnailData ?? artwork.imageData,
   let uiImage = UIImage(data: data) {
```

**Step 6: ArtworkComparisonView picker thumbnail (line 239)**

Replace:
```swift
if let data = artwork.imageData,
   let uiImage = UIImage(data: data) {
```
With:
```swift
if let data = artwork.thumbnailData ?? artwork.imageData,
   let uiImage = UIImage(data: data) {
```

**Step 7: DO NOT change these (they need full resolution):**
- `ArtworkDetailView.swift:49` — main detail image display
- `ArtworkDetailView.swift:351` — share image export
- `ArtworkGalleryView.swift:270` — ShareLink preview (needs full image for share)
- `PDFExportService.swift:121` — PDF export
- `AISuggestionService.swift` — image analysis

**Step 8: Build to verify**

Expected: BUILD SUCCEEDED

**Step 9: Commit**

```bash
git add "Little Artist/Components/Cards/ArtworkThumbnailView.swift" \
        "Little Artist/Components/Cards/TimelineEntryCardView.swift" \
        "Little Artist/Components/Cards/MemoryCardView.swift" \
        "Little Artist/Views/Artwork/ArtworkGalleryView.swift" \
        "Little Artist/Views/Artwork/ArtworkComparisonView.swift"
git commit -m "feat: use thumbnails in gallery grid, timeline cards, and comparison picker"
```

---

### Task 7: Final Build & Smoke Test

**Step 1: Clean build**

```bash
xcodebuild -project "Little Artist.xcodeproj" -scheme "Little Artist" -destination "platform=iOS Simulator,name=iPhone 17 Pro" clean build
```

Expected: BUILD SUCCEEDED

**Step 2: Verify no regressions**

Manually test on simulator:
- Add artwork from camera → verify image appears in gallery
- Add artwork from photo library → verify thumbnail loads in grid
- Open artwork detail → verify full-resolution image shows
- Check batch import → verify all images compressed

**Step 3: Final commit (if any cleanup needed)**
