# BandMole

Start here: [Docs index](docs/index.md)

---

> A song scroller and lyrics reader for musicians.

BandMole is a Flutter application designed for musicians and performers to display, customize, and automatically scroll lyrics and chord charts during practice and live performances.

---

## Current Implementation Status

BandMole is currently in the Release 1 / Songs Panel prototype phase. The shipped app includes a recursive song-library flow with persisted root-directory selection, Android Storage Access Framework support, UTF-8 decoding safeguards, responsive lyric scrolling, theme persistence, and declarative routing.

The later feature areas — Song Groups, ChordPro Editor, Song Charts, Metadata, and Data Import/Export — are still part of the planned roadmap rather than implemented in the current codebase.

---

## Features

- **Automated Lyrics Scrolling**:
  - Continuous, linear auto-scrolling with configurable scroll speeds (1 to 99).
  - Play / Stop toggle with immediate halt on touch gestures or stop button.
  - Quick navigation controls: **Go to Start** and **Go to End** driven by a unified scroll-command state in Riverpod.
  - Automatic button state updates, disabling transport buttons when already at the start or end, or when content fits within the screen, and re-evaluating that state when the window is resized.
  - Responsive song rendering that splits chord charts into side-by-side columns on wide desktop windows.

- **Typography & Readability**:
  - Monospaced typography (`Consolas`) to maintain accurate alignment of chords and lyrics.
  - Live font size adjustments, bounded with minimum size constraints, with instant visual feedback.
  - ChordPro-style chord markers are rendered as rich chord-and-lyric lines, with transposition controls enabled only for ChordPro files.

- **Song File Management**:
  - Repository-based song loading flow that separates the UI from file access and decoding concerns.
  - A single recursively scanned root song directory, with file and path problems surfaced as warnings.
  - Platform-specific directory access behind a repository abstraction, with persisted permissions or handles on Android and Web where supported.
  - UTF-8 encoding validation and malformed character handling.
  - Windows picker shows a single combined filter for allowed song files (`.cho`, `.crd`, `.chopro`, `.chordpro`, `.pro`, and `.txt`) instead of separate file-type entries.
  - Renamed or moved songs are matched using filename heuristics, with manual relinking when a match is ambiguous and broken-link status when no match is found.
  - `MainView` delegates snackbars and navigation to a dedicated `SongLoaderEffectsListener`, keeping the page layout focused on composition.

- **Theme Preferences**:
  - Customizable color themes, including dark themes optimized for low-light stage performance.
  - Asynchronous theme persistence via local preferences.

- **Declarative Navigation**:
  - Centralized route handling with `GoRouter` and nested named routes for the main screen, lyrics view, and preferences view.
  - The lyrics route expects a `Song` payload and redirects back home if it is opened without one.
  - Song and preference transitions are handled through `MaterialApp.router` instead of imperative page pushes.

---

## Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) `3.47.1` pinned by `.fvmrc`, with the project-pinned Dart SDK constraint `^3.13.1`
- **State Management**: [Flutter Riverpod](https://riverpod.dev/) (`flutter_riverpod` + `riverpod_annotation` / `riverpod_generator`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) with `MaterialApp.router`
- **Data Modeling**: [Freezed](https://pub.dev/packages/freezed) immutable state objects
- **Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) for persistent configuration
- **File System**: repository-based, platform-specific directory access with `filepicker_windows` used only by the Windows picker implementation

---

## Project Structure

```text
lib/
|-- main.dart                  # Application entry point
`-- src/
    |-- app.dart               # MaterialApp configuration and route handling
    |-- core/
    |   `-- widgets/
    |       |-- tool_tip_raised_button_widget.dart
    |       `-- tool_tip_rounded_text_widget.dart
    `-- features/
        |-- lyrics_scroller/
        |   |-- domain/
        |   |   |-- auto_scrollable_text.dart
        |   |   `-- song_formatting.dart
        |   `-- presentation/
        |       |-- providers/
        |       |   |-- auto_scrollable_text_provider.dart
        |       |   `-- song_transpose_provider.dart
        |       |-- views/
        |       |   `-- song_view.dart
        |       `-- widgets/
        |           |-- auto_scrollable_text_widget.dart
        |           `-- song_text_renderer.dart
        |-- preferences/
        |   |-- data/
        |   |   `-- preference_service.dart
        |   |-- domain/
        |   |   `-- app_themes.dart
        |   `-- presentation/
        |       |-- providers/
        |       |   `-- app_themes_provider.dart
        |       `-- views/
        |           `-- preferences_view.dart
        `-- song_loader/
            |-- data/
            |   |-- io_song_file_reader.dart
            |   |-- song_file_picker.dart
            |   |-- song_file_reader.dart
            |   |-- song_repository_impl.dart
            |   |-- unsupported_song_file_picker.dart
            |   `-- windows_song_file_picker.dart
            |-- domain/
            |   |-- song.dart
            |   |-- song_file.dart
            |   `-- song_repository.dart
            `-- presentation/
                |-- providers/
                |   |-- song_loader_controller.dart
                |   |-- song_repository_provider.dart
                |   |-- song_repository_provider_io.dart
                |   `-- song_repository_provider_stub.dart
                |-- widgets/
                |   `-- song_loader_effects_listener.dart
                `-- views/
                    `-- main_view.dart
    `-- navigation/
        |-- app_router.dart
        `-- app_routes.dart
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `3.47.1` (or FVM using `.fvmrc`); the current Dart SDK constraint is `^3.13.1`
- Supported desktop/mobile platform toolchain, for example Windows C++ build tools for Windows desktop

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/DanielDeLeonardis/bandmole.git
   cd bandmole
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code (Freezed & Riverpod):
   ```bash
   dart run build_runner build
   ```

4. Run the application:
   ```bash
   flutter run
   ```

---

## Testing & Static Analysis

Run the full test suite:
```bash
flutter test
```

Run static analysis:
```bash
dart analyze
```

Run feature branch coverage and enforce the 80% target:
```powershell
powershell -ExecutionPolicy Bypass -File tool/coverage.ps1
```
The gate requires LCOV `BRDA` branch records and exits clearly when the active
collector only emits line coverage.

Run the Release 1 integration workflow on a connected platform:
```bash
flutter test integration_test/release_1_workflow_test.dart -d windows
flutter test integration_test/release_1_workflow_test.dart -d <android-device-id>
```

Android library access uses a persisted Storage Access Framework tree grant. The
device workflow should select a shared-storage folder, verify nested song
browsing and loading, force-stop and relaunch, then verify the same root remains
available. Cancelled selections and revoked grants are surfaced as recoverable
warnings and can be reselected through the folder button.

---

## Documentation

Comprehensive product and technical documentation is maintained in the [`docs/`](docs/index.md) directory:

- [Documentation Index](docs/index.md) — Directory map and reading guide
- [Roadmap](docs/roadmap.md) — Release sequence, milestones, and priority tiers
- [Product Requirements Document](docs/prd.md) — Product goals, scope, and technical constraints
- [Requirements](docs/requirements.md) — Detailed feature specifications, success criteria, and edge cases
- [Architecture](docs/architecture.md) — Component breakdown, state flows, and layered architecture
- [Architecture Recommendations](docs/architecture_recommendations.md) — Modularity guidelines and implemented refactoring roadmap

