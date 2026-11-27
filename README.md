# BandMole

Start here: [Docs index](docs/index.md)

---

> A song scroller and lyrics reader for musicians.

BandMole is a Flutter application designed for musicians and performers to display, customize, and automatically scroll lyrics and chord charts during practice and live performances.

---

## Current Implementation Status

BandMole implements Release 1 (Songs Panel and lyrics performance) and Release 2 (Song Groups). The app includes a recursively scanned song library, persisted root selection, Android Storage Access Framework access, lyric scrolling, and native gigs and sets backed by SQLite.

Release 3 (ChordPro Editor) is implemented on desktop with Android SAF device write verification still open; Song Charts, Metadata, and Data Import/Export remain planned. See the [roadmap](docs/roadmap.md) for their scope.

---

## Features

- **Automated Lyrics Scrolling**:
  - Continuous, linear auto-scrolling with configurable scroll speeds (1 to 99).
  - Play / Stop toggle with immediate halt on touch gestures or stop button.
  - Quick navigation controls: **Go to Start** and **Go to End** driven by a unified scroll-command state in Riverpod.
  - Automatic button state updates, disabling transport buttons when already at the start or end, or when content fits within the screen, and re-evaluating that state when the window is resized.
  - Single-column auto-scrolling song rendering in performance view so scrolling stays predictable for long songs.

- **Typography & Readability**:
  - Monospaced typography (`Consolas`) to maintain accurate alignment of chords and lyrics.
  - Live font size adjustments, bounded with minimum size constraints, with instant visual feedback.
  - ChordPro-style chord markers are rendered as rich chord-and-lyric lines, with transposition controls enabled only for ChordPro files.

- **Song File Management**:
  - Repository-based song loading flow that separates the UI from file access and decoding concerns.
  - A single recursively scanned root song directory, with file and path problems surfaced as warnings.
  - Platform-specific directory access behind a repository abstraction, including persisted Android Storage Access Framework grants. Web support is planned.
  - UTF-8 encoding validation and malformed character handling.
  - Windows picker shows a single combined filter for allowed song files (`.cho`, `.crd`, `.chopro`, `.chordpro`, `.pro`, and `.txt`) instead of separate file-type entries.
  - Missing gig-song references are marked as broken links and can be relinked manually. Automatic filename-heuristic matching remains a requirement, not a verified behavior of the current validator.
  - `MainView` delegates song-loading messages and the loaded-song callback to `SongLoaderEffectsListener`.

- **Gigs & Sets (Release 2)**:
  - Create, edit, delete, and reorder gigs, sets, and song assignments; gig and set titles are checked for duplicates after whitespace and case normalization.
  - Store gigs transactionally in native SQLite, including migration of legacy JSON gig data.
  - Keep song assignments relative to the selected library root; show missing songs as broken links that can be removed or relinked.
  - Open a gig song in performance set mode with previous/next navigation across sets. While a set is open, the Songs library and panel tabs are locked; **Close set** restores normal navigation.

- **ChordPro Editor (Release 3)**:
  - Create or edit ChordPro songs, preview formatted lyrics and chords with all 26 Release 3 ChordPro 6.101 directives (plus `%{meta}` interpolation and per-line chord styling), inspect directives and sections with keyboard-accessible reordering, and insert chords/directives from draggable palettes.
  - Convert plain-text chord sheets explicitly (keeping source read-only until converted, with conversion ambiguity notices) and save a separate `.chopro` file with an explicit overwrite confirmation dialog while leaving the source unchanged. Save/Discard/Cancel protects unsaved edits, and saving automatically refreshes loaded gigs to clear matching broken links.
  - Atomic desktop saves behind a platform-neutral `ChordProSongStore`, SQLite-backed global custom directives (with legacy `SharedPreferences` migration), per-song custom directives, `scroll_speed`, and dismissed hints persist locally. Android SAF write verification on device remains open.

- **Theme Preferences**:
  - Customizable color themes, including dark themes optimized for low-light stage performance.
  - Asynchronous theme persistence via local preferences.

- **Declarative Navigation**:
  - Centralized route handling with `GoRouter` and nested named routes for the main screen, lyrics view, preferences view, and editor.
  - The lyrics route expects a `Song` payload and redirects back home if it is opened without one.
  - Preferences and the standalone lyrics route use `MaterialApp.router`; the active song is displayed inside `MainView`.

---

## Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) `3.47.1` pinned by `.fvmrc`, with the project-pinned Dart SDK constraint `^3.13.1`
- **State Management**: [Flutter Riverpod](https://riverpod.dev/) (`flutter_riverpod` + `riverpod_annotation` / `riverpod_generator`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) with `MaterialApp.router`
- **Data Modeling**: [Freezed](https://pub.dev/packages/freezed) immutable state objects
- **Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) for configuration; SQLite (`sqflite` / `sqflite_common_ffi`) for native gig/set data and global custom ChordPro directives
- **File System**: repository-based, platform-specific directory access and atomic song writes (`SongRepository`, `ChordProSongStore`), with `filepicker_windows` used only by the Windows picker implementation

---

## Project Structure

```text
lib/
|-- main.dart                  # Application entry point
|-- l10n/                      # ARB localization resources and generated AppLocalizations
`-- src/
    |-- app.dart               # MaterialApp configuration and route handling
    |-- core/
    |   `-- widgets/
    |       |-- tool_tip_raised_button_widget.dart
    |       `-- tool_tip_rounded_text_widget.dart
    |-- features/
        |-- chordpro_editor/
        |   |-- data/             # Io/unsupported song stores, SQLite directive repository
        |   |-- domain/           # ChordProDocument, store and preferences contracts
        |   `-- presentation/     # Editor view, palettes, outline, dialogs, providers
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
        |-- song_groups/
        |   |-- data/             # SQLite repository and load validation
        |   |-- domain/           # Gig, set, song assignment, repository contract
        |   `-- presentation/     # Gigs controller, panel, dialogs, localization
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

Run the Release 2 gig/set workflow on Windows:
```bash
flutter test integration_test/release_2_workflow_test.dart -d windows
```
This exercises setlist interactions, repository reopening, and keyboard navigation.

Run the Release 3 desktop editor round-trip:
```bash
flutter test integration_test/release_3_workflow_test.dart -d windows
```
This exercises read-only `.txt` conversion, keyboard section reordering, SQLite custom-directive persistence, `Ctrl+S`/`Esc` shortcuts, gig broken-link refresh, `scroll_speed` reload, and explicit overwrite confirmation.
The 80% branch-coverage gate is a target checked by `tool/check_coverage.dart` across all feature areas and shared navigation, not a static percentage asserted by this README.

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
- [Release 2 Technical Debt](docs/release_2_tech_debt.md) — Resolved cross-cutting findings and verification limits
- [Release 3 Technical Debt](docs/release_3_tech_debt.md) — Final Release 3 review, resolved findings, verification baseline, and remaining open items

