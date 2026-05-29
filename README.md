# Frame It

An iOS 26+ app that wraps a chosen photo in a customizable **frame** displaying its
capture metadata — device, date, shutter, ISO, focal length, lens, and location.
Built with SwiftUI and Apple's Liquid Glass design language.

## Features

- **Photo library** — browse your library and albums, pick a shot to frame.
- **Auto metadata** — reads EXIF (device, exposure, focal length, lens, capture app)
  via ImageIO; reverse-geocodes the photo's embedded GPS into a place name (no location
  permission requested).
- **Editor** — customize the frame live:
  - Background color, symmetric padding + independent bottom padding, corner radius.
  - Typography: font catalog with category filter (Sans / Serif / Rounded / Mono),
    size, bold, italic. Premium fonts marked with a gold crown.
  - Metadata fields grouped into **Device / Exposure / Place**, toggled as chips.
  - Two layouts: **Minimal** (centered caption block) and **Advanced** (three columns —
    Exposure · Device · Place).
  - Place column: **Time** (city/country + date + time) or **Map** (a minimap snapshot
    with a center pin; custom pin glyphs are premium).
- **Export** — render the framed photo at full source resolution and save to Photos or
  share. The on-screen preview is the single source of truth, so the export always matches.

## Requirements

- Xcode 26 (iOS 26 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

The Xcode project is **generated** from `project.yml`; `FrameIt.xcodeproj` is git-ignored
and never hand-edited.

## Build & Test

```bash
# Regenerate the project after changing project.yml or adding/removing source files
xcodegen generate

# Build (no booted simulator required)
xcodebuild -project FrameIt.xcodeproj -scheme FrameIt \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build

# Run the test suite (Swift Testing)
xcodebuild -project FrameIt.xcodeproj -scheme FrameIt \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Architecture

SwiftUI + **`@Observable` MVVM** (not `ObservableObject`). View models depend on
protocol-based services so they can be unit-tested with mocks.

```
FrameIt/
  App/          @main entry + RootView (TabView: Photos + Settings)
  Features/     one folder per screen — Library, Editor, Settings
  Core/
    Photos/     PhotoLibraryService (PhotoKit wrapper), PhotoAsset
    Metadata/   MetadataService (EXIF + CLGeocoder), PhotoMetadata, ExposureFormatting
    Frame/      FrameStyle, FrameLayout, FramePreview, FrameRenderer, Pin/Map helpers
    Export/     ExportService (save to Photos + share sheet)
  Design/       Theme, Typography, GlassComponents (reusable Liquid Glass UI)
FrameItTests/   Swift Testing suites
```

### Data flow (editor → export)

`PHAsset` → `PhotoLibraryService` (full-res `Data`) → `MetadataService` (`PhotoMetadata`)
→ bound into a `FrameStyle` → **`FramePreview`** → `FrameRenderer` (`ImageRenderer`) →
`ExportService`.

## Conventions

- **iOS 26+, Liquid Glass only** — no material/older-OS fallback path.
- **No location permission** — GPS comes from the photo's own EXIF; only network
  reverse-geocoding turns coordinates into a place name.
- Swift 5 language mode (Swift 6 upgrade is a deliberate later task).

## Roadmap

Templates (SwiftData) → iCloud sync (CloudKit) → StoreKit 2 monetization
(Free / one-time / subscription) → iPad (`NavigationSplitView`).

## License

Proprietary — all rights reserved.
