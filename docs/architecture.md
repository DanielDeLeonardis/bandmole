# Architectural Analysis of BandMole

> Documenting the architectural design, components, data flows, and technical characteristics of the BandMole codebase.

---

## 1. Executive Summary

BandMole is an offline-first Flutter application targeting Windows 10 and Android 10 first, with Linux and Web planned next. The codebase implements Release 1 song-library and lyrics-performance flows, Release 2 gig/set management, and Release 3 ChordPro editing on desktop (with Android SAF device write verification remaining open; see [Release 3 Technical Debt](release_3_tech_debt.md)). Native gig data and global custom ChordPro directives are persisted in SQLite; song assignments use library-root-relative paths.

The architecture blends Flutter Riverpod state management, Freezed immutable data models, and Flutter widget lifecycle hooks with platform abstractions for file picking, decoding, and writing.

Auto-scroll jump actions are unified into a single `AutoScrollableTextNotifier` flow. Instead of a separate event stream, jump navigation is represented as a one-shot `pendingCommand` on the shared `AutoScrollableText` state.

The codebase is organized in a feature-first structure under `lib/src/` with shared UI helpers in `core/` and feature folders for `chordpro_editor`, `lyrics_scroller`, `preferences`, `song_groups`, and `song_loader`.

Instrument-profile conditional directive filtering (e.g., `{define-ukulele: ...}`), Song Charts, Metadata, and Data Import and Export remain planned. The implemented architecture includes a recursively scanned song library, persisted access state, gig/set validation, broken-link handling, performance set mode, and the Release 3 ChordPro 6.101 editor and renderer.

---

## 2. High-Level System Architecture

The application is structured into five primary vertical tiers:

```text
Presentation Layer
  - Views: MainView, GigsPanelView, SongView, ChordProEditorView, PreferenceView
  - Widgets: AutoScrollableTextWidget, SongTextRenderer, ChordProChordPalette, ChordProDirectivePalette, ChordProOutlinePanel, chordpro_editor_dialogs, custom tooltip widgets
  - Reads and writes Riverpod state

Navigation & Routing
  - appRouterProvider (GoRouter)
  - Nested named routes for main, lyrics, preferences, and editor
  - Lyrics route guarded by required `Song` payload; editor route guarded by `ChordProEditorRequest`

State Management & Logic
  - AutoScrollableTextNotifier (Notifier<AutoScrollableText>)
  - SongTransposeNotifier (Notifier<int>)
  - AppThemeNotifier (AsyncNotifier<ThemeData>)
  - SongLoaderController (AsyncNotifier<Song?>)
  - GigsController (gig/set CRUD, selection, and set-mode navigation)

Services & Infrastructure
  - PreferenceService (SharedPreferences)
  - SongRepository + SongFileReader; MainView coordinates library-root selection and scanning
  - Platform-specific directory access and persisted access capabilities
  - GigRepository / SqliteGigRepository (native SQLite and legacy JSON migration)
  - ChordProSongStore / IoChordProSongStore / UnsupportedChordProSongStore (conditional IO/stub providers; atomic desktop writes and Android SAF write channel)
  - ChordProPreferencesRepository / SqliteChordProPreferencesRepository / SharedPreferencesChordProPreferencesRepository (SQLite global custom directives with legacy SharedPreferences migration, plus hint dismissal)

Domain Models
  - Song, SongFile, SongRepository, Gig, SongSet, GigSong, GigRepository, ChordProDocument, ChordProSongStore, ChordProPreferencesRepository, AutoScrollableText (Freezed), SongFormattingResult, AppTheme
```

---

## 3. Detailed Component Breakdown

### 3.1 Presentation Layer (`lib/src/features/.../presentation/`)

- **`MainView` (`lib/src/features/song_loader/presentation/views/main_view.dart`)**
  - The main screen hosts the Songs library, embedded song display, Gigs panel, and navigation action to preferences.
  - Dispatches song loading to `SongLoaderController`, while `SongLoaderEffectsListener` handles success/error outcomes via a lifecycle-safe listener.
  - Uses responsive panel tabs on narrow screens and a side-by-side library on wide screens. When a gig song opens in set mode, it blocks library and tab input until **Close set** is selected.
  - Uses the centralized router for standalone lyrics and preferences routes; the performance song display is embedded in `MainView`.
  - Resets transpose state before opening non-ChordPro songs so the lyrics view starts at concert pitch for plain text files.

- **`GigsPanelView` (`lib/src/features/song_groups/presentation/views/gigs_panel_view.dart`)**
  - Presents gig/set selection, editing, reordering, and song assignment, including missing-song recovery.
  - `GigsController` holds selected gig, set, and active song indices; previous/next navigation crosses set boundaries without wrapping after the last set.

- **`ChordProEditorView` (`lib/src/features/chordpro_editor/presentation/views/chordpro_editor_view.dart`)**
  - Coordinates raw ChordPro editing, live `SongTextRenderer` preview, and modular child widgets: `ChordProChordPalette`, `ChordProDirectivePalette` (`chordpro_palettes.dart`), `ChordProOutlinePanel` (`chordpro_outline_panel.dart`), and editor dialogs (`chordpro_editor_dialogs.dart`).
  - Consumes `ChordProSongStore` and `ChordProPreferencesRepository` via Riverpod providers (`chordpro_song_store_provider*.dart`, `chordpro_preferences_provider*.dart`) without importing `dart:io` or `SharedPreferences` directly.
  - `ChordProDocument` preserves comments, unknown directives, whitespace, and line endings, and performs conservative, explicit conversion from plain-text sheets (`convertDetailed`, reporting ambiguous lines and keeping plain-text source read-only until conversion is triggered). `ChordProSongStore` writes a separate `.chopro` file while leaving the source intact, with an explicit overwrite confirmation dialog when the destination already exists.
  - Supports keyboard shortcuts (`Ctrl+S`, `Esc`), keyboard-accessible section reordering, and a dirty-editor guard (Save, Discard, or Cancel restoring focus). When returning to `MainView` after a save, `MainView._openEditor` refreshes the song library and re-validates gigs so newly created `.chopro` files clear matching broken links immediately. Android SAF write behavior still requires device-level verification.

- **`SongView` (`lib/src/features/lyrics_scroller/presentation/views/song_view.dart`)**
  - The primary performance display.
  - Accepts raw song lyrics text via its constructor.
  - Wraps `AutoScrollableTextWidget` and provides floating action buttons for font size adjustment, scroll speed, start/stop scrolling, and boundary jumps (`Go to start`, `Go to end`).
  - Exposes chord transposition controls only for ChordPro songs and forwards the active semitone offset into the lyric formatter.
  - Interacts with state through a single Riverpod notifier:
    - Reads `autoScrollableTextProvider` for font size, speed, scroll toggle, and boundary flags.
    - Dispatches all scroll-related actions via `autoScrollableTextProvider.notifier`.
    - Reads `songTransposeProvider` for chord transposition state.
  - Disables the scroll speed controls when the rendered lyrics fit within the viewport, and recalculates that enabled state when the window is resized.

- **`PreferenceView` (`lib/src/features/preferences/presentation/views/preferences_view.dart`)**
  - Displays a `ListView` of selectable color theme cards.
  - Dispatches theme selection changes directly to `appThemeProvider.notifier.setAppTheme()`.

- **`AutoScrollableTextWidget` (`lib/src/features/lyrics_scroller/presentation/widgets/auto_scrollable_text_widget.dart`)**
  - Core scroll rendering engine extending `ConsumerStatefulWidget` with `TickerProviderStateMixin`.
  - Manages a local `ScrollController` attached to a `SingleChildScrollView`.
  - Computes dynamic linear scroll durations based on `scrollSpeed`, `maxScrollExtent`, and `offset`.
  - Listens to `autoScrollableTextProvider` state updates, including `pendingCommand`, to adjust active animations and handle jump requests.
  - Observes viewport metric changes so resize events trigger a fresh boundary check, keeping `isAtStart`, `isAtEnd`, and the scroll speed control state in sync with the layout.
  - Intercepts scroll notifications via `NotificationListener<ScrollNotification>` to detect user touches and naturally completed scrolls.
  - Renders parsed song content through `SongFormatter` and `SongTextRenderer`, preserving plain text lyrics while adding ChordPro 6.101 metadata, chord diagrams, styling directives, and single-column auto-scrolling (`allowMultiColumnLayout: false`, since multi-column layout only suits songs that fit on one screen).

- **Supporting Widgets (`lib/src/core/widgets/`)**
  - `ToolTipRaisedButton`: A reusable elevated button wrapped in a `Tooltip`.
  - `ToolTipRoundedText`: A pill-shaped numeric display for font size and scroll speed.

---

### 3.2 State Management & Application Logic (`lib/src/features/.../presentation/providers/`)

State management uses Riverpod:

1. **`AutoScrollableTextNotifier` (`auto_scrollable_text_provider.dart`)**
   - Manages the core reading session state encapsulated in the Freezed model `AutoScrollableText`.
   - Fields tracked: `isScrolling`, `isAtStart`, `isAtEnd`, `scrollSpeed` (1-99), `textFontSize` (min 8.0), and `pendingCommand` for one-shot jump actions.
   - Manages state transformations:
     - `increaseTextFontSize`
     - `decreaseTextFontSize`
     - `increaseScrollSpeed`
     - `decreaseScrollSpeed`
     - `toggleIsScrolling`
     - `setIsScrolling`
     - `jumpToStart`
     - `jumpToEnd`
     - `clearPendingCommand`
     - `resetScrollState`
     - `setPositionState`
   - `setPositionState()` is called after initial layout and after viewport metric changes so boundary flags stay accurate when the window size changes.
   - Defined via manual `NotifierProvider`.

2. **`AppThemeNotifier` (`app_themes_provider.dart`)**
  - Manages global theme state as an `AsyncNotifier<ThemeData>`.
  - Asynchronously loads persisted preferences from disk during `build()` and falls back to `AppTheme.blueDark`.
  - Persists updates to disk via `preference_service.dart`.

3. **`SongTransposeNotifier` (`song_transpose_provider.dart`)**
   - Manages the semitone offset used to transpose displayed chords.
   - Exposes increment, decrement, and reset actions for the lyrics view.

4. **`SongLoaderController` (`song_loader_controller.dart`)**
   - Manages the song-loading workflow as an `AsyncNotifier<Song?>`.
   - Dispatches repository calls for song file selection and loading.
   - Exposes loading, success, and error states to `SongLoaderEffectsListener`, which reacts with snackbars and invokes the loaded-song callback after the current frame has settled.

---

### 3.3 Data & Infrastructure Services (`lib/src/features/.../data/`)

- **`song_repository_impl.dart`**
  - Implements the repository boundary for file access.
  - Delegates file selection to a `SongFilePicker` and file-byte reading to a `SongFileReader`.
  - Returns `Song` models that carry a platform-neutral `SongFile` rather than a raw `dart:io File`.
- **Target directory access and scanning services**
  - Select and persist one root song directory using platform-appropriate picker permissions or handles.
  - Recursively scan supported files, report file and path warnings, and retain unavailable roots for later restoration.
  - Validate gig-song references against the current library, offer manual relinking for missing songs, and preserve unresolved references as broken links. Automatic filename-heuristic matching remains planned.
- **`windows_song_file_picker.dart`**
  - Configures the Windows file dialog with a single combined filter for allowed song files (`.cho`, `.crd`, `.chopro`, `.chordpro`, `.pro`, and `.txt`) so the dialog shows matching files without forcing the user to choose a specific type.

- **`preference_service.dart`**
  - Wraps `SharedPreferences` to load and save `themeData` by enum string representation.

- **`sqlite_gig_repository.dart`**
  - Persists gigs and sets transactionally in native SQLite through `GigRepository`.
  - Uses a versioned schema and migrates legacy JSON gig records from `bandmole_gigs_store`.

- **`io_chordpro_song_store.dart` / `unsupported_chordpro_song_store.dart`**
  - Implements the pure-Dart `ChordProSongStore` contract behind conditional IO/stub providers (`chordpro_song_store_provider*.dart`).
  - Performs atomic temp-file-and-rename desktop writes (with fallback cleanup on Windows rename failure) and delegates Android SAF writes to `AndroidSafLibrary.writeSong`.

- **`sqlite_chordpro_preferences_repository.dart`**
  - Implements `ChordProPreferencesRepository` behind conditional IO/stub providers (`chordpro_preferences_provider*.dart`).
  - Persists global custom directives in a native SQLite `custom_directives` table with one-time migration from legacy `SharedPreferences` (`chordpro_custom_directives`), tracks dismissed hint state, and provides `SharedPreferencesChordProPreferencesRepository` as a non-IO fallback.

Jump navigation is carried by the shared notifier state rather than a separate `StreamController`.

---

### 3.4 Domain Models (`lib/src/features/.../domain/`)

- **`Song` (`song.dart`)**
  - Represents a loaded song file.
  - Contains `file` (`SongFile`), `text` (`String?`), and `isMalformed` (`bool`).
  - Exposes `canTranspose` so the UI can distinguish ChordPro songs from plain text songs.

- **`SongFile` (`song_file.dart`)**
  - A platform-neutral handle for a selected song file path.
  - Provides extension-based ChordPro detection used to decide whether transpose controls should be enabled.

- **`SongRepository` (`song_repository.dart`)**
  - Domain-level contract for picking and loading song files.

- **`Gig`, `SongSet`, `GigSong`, `GigRepository` (`lib/src/features/song_groups/domain/`)**
  - Model gig/set ordering and relative song references behind the gig persistence contract.

- **`ChordProDocument`, `ChordProSongStore`, `ChordProPreferencesRepository` (`lib/src/features/chordpro_editor/domain/`)**
  - Pure-Dart ChordPro document parser, section reorderer, custom-directive validator, conservative plain-text converter (`convertDetailed`), and platform-neutral persistence contracts.

- **`AutoScrollableText` (`auto_scrollable_text.dart`)**
  - An immutable Freezed value object representing reading and scrolling state.
  - Includes `pendingCommand` so jump navigation can be expressed as part of the same state object that stores scrolling flags and user preferences.

- **`SongFormattingResult` / `SongSection` / `SongLine` (`song_formatting.dart`)**
  - Pure Dart formatting models that parse plain lyrics or ChordPro 6.101 charts into renderable sections, supporting all 26 Release 3 directives, `%{meta}` interpolation, transposed inline `{chord}` diagrams, per-line chord style overrides, and semitone transposition.
  - `SongTextRenderer` localizes app-owned metadata chip labels and default section headings via `AppLocalizations` while leaving song content and user-authored labels untouched.

- **`AppTheme` (`app_themes.dart`)**
  - An enum (`greenLight`, `greenDark`, `blueLight`, `blueDark`) paired with a global dictionary `appThemeData` mapping to standard Flutter `ThemeData` objects.

---

## 4. Key Data & Control Flows

### 4.1 Song Selection & Loading Flow

```text
[User opens the Songs Panel]
  -> MainView restores or selects the persisted root directory
  -> Android SAF scan or SongLibrary.scanDirectory lists supported files
  -> GigLoadValidator checks saved relative song references for missing files
  -> Missing assignments can be manually relinked; unresolved references remain broken links
  -> User selects a song and SongLoaderController loads it through SongRepository
  -> Decode bytes as UTF-8
     - Success: isMalformed = false
     - Failure: fallback with allowMalformed = true, isMalformed = true
  -> SongLoaderEffectsListener resets transpose state for plain-text songs
  -> MainView displays the loaded song in its embedded SongView

[User selects a gig song]
  -> GigsController enters set mode and tracks the active set/song indices
  -> MainView blocks Songs library and tab input while set mode remains active
  -> Previous/next moves across set boundaries; Close set clears active navigation
```

### 4.2 Auto-Scroll Execution & Animation Flow

```text
[User taps Play Icon]
  -> SongView calls autoScrollableTextProvider.notifier.toggleIsScrolling()
  -> Riverpod emits updated AutoScrollableText (isScrolling: true)
  -> AutoScrollableTextWidget.manual listener detects state change
  -> Calculates duration = (maxScrollExtent - offset) / (speed * 10)
  -> ScrollController.animateTo(maxScrollExtent, curve: Curves.linear)
  -> Scroll notifications update setPositionState(screenOffset, screenMaxExtent)
  -> User manually touches / drags -> setIsScrolling(false), halts animation
  -> User taps Stop -> ScrollController.jumpTo(offset), setIsScrolling(false)
  -> Reaches bottom -> ScrollEndNotification triggers setIsScrolling(false)
```

### 4.3 Jump Navigation Flow

```text
[User taps 'Go to end' / 'Go to start']
  -> SongView calls autoScrollableTextProvider.notifier.jumpToEnd() / jumpToStart()
  -> AutoScrollableTextNotifier sets pendingCommand on AutoScrollableText
  -> AutoScrollableTextWidget.manual listener consumes pendingCommand and clears it
  -> AutoScrollableTextWidget animates to minScrollExtent or maxScrollExtent
  -> Post-frame callback triggers setPositionState to update isAtStart and isAtEnd
  -> SongView rebuilds and the appropriate button disables automatically
```

---

## 5. Architectural Strengths

1. **Reactive UI State Binding**: Core UI controls subscribe to immutable state generated by Freezed through Riverpod.
2. **Robust Scroll Synchronization**: Post-frame callbacks and `ScrollNotification` listeners help avoid mutating provider state during Flutter build phases.
3. **Unified Command State**: Jump navigation uses the same notifier and model as the rest of the scroll controls, which keeps state transitions easier to follow and avoids stream lifecycle management.
4. **Presentation Controller Separation**: `SongLoaderController` keeps the file-picking workflow out of `MainView`, which leaves the view focused on user interaction and navigation.
5. **Declarative Routing**: `MyApp` uses `MaterialApp.router` with a centralized `GoRouter`, which standardizes route handling across the app and makes future deep-link support easier to add.
6. **Repository-Based File Access**: Song loading flows through `SongRepository`, `SongFilePicker`, and `SongFileReader`, which keeps file selection and decoding out of the presentation layer and makes the data boundary easier to test.
7. **Rich Song Presentation**: The formatter/parser layer understands ChordPro 6.101 markup, metadata, chord diagrams, styling directives, transposition, and single-column auto-scrolling in performance view (`SongTextRenderer` also supports multi-column layouts where appropriate), while plain-text songs keep transpose controls disabled and reset to concert pitch.
8. **Feature-First Layout**: Related code lives together under `lib/src/features/`, which makes the current implementation areas and planned release boundaries easier to navigate.
9. **Defensive Decoding**: File ingestion accounts for character encoding anomalies, preventing crashes on non-UTF-8 song files.
10. **Measurable Test Target**: Each feature area targets at least 80% branch coverage, with integration coverage for file browsing and persistence alongside unit and widget tests.

---

## 6. Architectural Notes

1. `SongLoaderEffectsListener` owns the snackbar and navigation side effects for the song-loading flow, keeping the page layout focused on composition.
2. The router uses a grouped route tree with payload guards on `lyrics` (`Song`) and `editor` (`ChordProEditorRequest`), which keeps route ownership clear without adding unnecessary shells or authorization layers.
3. On Windows desktop (`!kIsWeb && defaultTargetPlatform == TargetPlatform.windows`), `lib/src/app.dart` temporarily wraps `MaterialApp.router` in `ExcludeSemantics` to mitigate upstream Flutter `accessibility_bridge.cc` `ui::AXTree` errors while screen-reader support remains a later-phase goal (tracked in `R3-TD-06` in [release_3_tech_debt.md](release_3_tech_debt.md)).
