# Architectural Analysis of BandMole

> Documenting the current architectural design, components, data flows, and technical characteristics of the BandMole codebase.

---

## 1. Executive Summary

BandMole is a specialized Flutter desktop application for loading, displaying, and smoothly auto-scrolling song lyrics and chord charts. The codebase is organized around a small set of focused features: file selection and encoding validation, configurable auto-scrolling with transport playback controls, text customization, and persistent user themes.

The current architecture blends Flutter Riverpod state management, Freezed immutable data models, and Flutter widget lifecycle hooks with platform abstractions for file picking and decoding.

One important architectural change is that auto-scroll jump actions are now unified into a single `AutoScrollableTextNotifier` flow. Instead of a separate event stream, jump navigation is represented as a one-shot `pendingCommand` on the shared `AutoScrollableText` state.

The codebase is now organized in a feature-first structure under `lib/src/` with shared UI helpers in `core/` and feature folders for `lyrics_scroller`, `preferences`, and `song_loader`.

---

## 2. High-Level System Architecture

The application is structured into five primary vertical tiers:

```text
Presentation Layer
  - Views: MainView, SongView, PreferenceView
  - Widgets: AutoScrollableTextWidget, custom tooltip widgets
  - Reads and writes Riverpod state

Navigation & Routing
  - appRouterProvider (GoRouter)
  - Named routes for main, lyrics, and preferences

State Management & Logic
  - AutoScrollableTextNotifier (Notifier<AutoScrollableText>)
  - SongTransposeNotifier (Notifier<int>)
  - AppThemeNotifier (AsyncNotifier<ThemeData>)
  - SongLoaderController (AsyncNotifier<Song?>)

Services & Infrastructure
  - PreferenceService (SharedPreferences)
  - SongRepository + SongFileReader + SongFilePicker
  - WindowsSongFilePicker / UnsupportedSongFilePicker

Domain Models
  - Song, SongFile, SongRepository, AutoScrollableText (Freezed), SongFormattingResult, AppTheme
```

---

## 3. Detailed Component Breakdown

### 3.1 Presentation Layer (`lib/src/features/.../presentation/`)

- **`MainView` (`lib/src/features/song_loader/presentation/views/main_view.dart`)**
  - The initial landing screen.
  - Hosts the file picker entry point (`Open song`) and navigation action to preferences.
  - Dispatches song loading to `SongLoaderController`, then handles success/error outcomes via a lifecycle-safe manual listener that defers snackbars and navigation to post-frame callbacks.
  - Uses declarative named routes via `context.pushNamed()` to transition to `SongView` and `PreferenceView`.
  - Resets transpose state before opening non-ChordPro songs so the lyrics view starts at concert pitch for plain text files.

- **`SongView` (`lib/src/features/lyrics_scroller/presentation/views/song_view.dart`)**
  - The primary performance display.
  - Accepts raw song lyrics text via its constructor.
  - Wraps `AutoScrollableTextWidget` and provides floating action buttons for font size adjustment, scroll speed, start/stop scrolling, and boundary jumps (`Go to start`, `Go to end`).
  - Exposes chord transposition controls only for ChordPro songs and forwards the active semitone offset into the lyric formatter.
  - Interacts with state through a single Riverpod notifier:
    - Reads `autoScrollableTextProvider` for font size, speed, scroll toggle, and boundary flags.
    - Dispatches all scroll-related actions via `autoScrollableTextProvider.notifier`.
    - Reads `songTransposeProvider` for chord transposition state.

- **`PreferenceView` (`lib/src/features/preferences/presentation/views/preferences_view.dart`)**
  - Displays a `ListView` of selectable color theme cards.
  - Dispatches theme selection changes directly to `appThemeProvider.notifier.setAppTheme()`.

- **`AutoScrollableTextWidget` (`lib/src/features/lyrics_scroller/presentation/widgets/auto_scrollable_text_widget.dart`)**
  - Core scroll rendering engine extending `ConsumerStatefulWidget` with `TickerProviderStateMixin`.
  - Manages a local `ScrollController` attached to a `SingleChildScrollView`.
  - Computes dynamic linear scroll durations based on `scrollSpeed`, `maxScrollExtent`, and current `offset`.
  - Listens to `autoScrollableTextProvider` state updates, including `pendingCommand`, to adjust active animations and handle jump requests.
  - Intercepts scroll notifications via `NotificationListener<ScrollNotification>` to detect user touches and naturally completed scrolls.
  - Renders parsed song content through `SongFormatter` and `SongTextRenderer`, which preserve plain text lyrics while adding ChordPro-aware metadata and responsive two- or three-column layout support on wide screens.

- **Supporting Widgets (`lib/src/core/widgets/`)**
  - `ToolTipRaisedButton`: A reusable elevated button wrapped in a `Tooltip`.
  - `ToolTipRoundedText`: A pill-shaped numeric display for font size and scroll speed.

---

### 3.2 State Management & Application Logic (`lib/src/features/.../presentation/providers/`)

State management is implemented using Riverpod:

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
   - Exposes loading, success, and error states to `MainView`, which reacts with snackbars and navigation after the current frame has settled.

---

### 3.3 Data & Infrastructure Services (`lib/src/features/.../data/`)

- **`file_service.dart`**
  - Replaced by `SongRepositoryImpl`, which reads raw file bytes through `SongFileReader` and attempts strict UTF-8 decoding before falling back to `allowMalformed: true`.

- **`song_repository_impl.dart`**
  - Implements the repository boundary for file access.
  - Delegates file selection to a `SongFilePicker` and file-byte reading to a `SongFileReader`.
  - Returns `Song` models that carry a platform-neutral `SongFile` rather than a raw `dart:io File`.
- **`windows_song_file_picker.dart`**
  - Configures the Windows file dialog with a single combined filter for allowed song files (`.cho`, `.crd`, `.chopro`, `.chordpro`, `.pro`, and `.txt`) so the dialog shows matching files without forcing the user to choose a specific type.

- **`preference_service.dart`**
  - Wraps `SharedPreferences` to load and save `themeData` by enum string representation.

The former auto-scroll stream service is no longer part of the current implementation. Jump navigation is now carried by the shared notifier state rather than a separate `StreamController`.

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

- **`AutoScrollableText` (`auto_scrollable_text.dart`)**
  - An immutable Freezed value object representing reading and scrolling state.
  - Includes `pendingCommand` so jump navigation can be expressed as part of the same state object that stores scrolling flags and user preferences.

- **`SongFormattingResult` / `SongSection` / `SongLine` (`song_formatting.dart`)**
  - Pure Dart formatting models that parse plain lyrics or ChordPro-style chord charts into renderable sections.
  - Supports song metadata such as title, subtitle, key, artist, and capo, plus chord transposition on a semitone basis.

- **`AppTheme` (`app_themes.dart`)**
  - An enum (`greenLight`, `greenDark`, `blueLight`, `blueDark`) paired with a global dictionary `appThemeData` mapping to standard Flutter `ThemeData` objects.

---

## 4. Key Data & Control Flows

### 4.1 Song Selection & Loading Flow

```text
[User taps 'Open song']
  -> MainView dispatches to SongLoaderController.pickAndLoadSong()
  -> SongLoaderController invokes SongRepository.pickSongFile()
  -> If no file is selected, show a 'No song selected' SnackBar
  -> If a file is selected, call SongRepository.loadSong(file)
  -> Decode bytes as UTF-8
     - Success: isMalformed = false
     - Failure: fallback with allowMalformed = true, isMalformed = true
  -> MainView resets transpose state for plain-text songs, then calls context.pushNamed(AppRoutes.lyrics, extra: song)
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
3. **Unified Command State**: Jump navigation now uses the same notifier and model as the rest of the scroll controls, which keeps state transitions easier to follow and avoids stream lifecycle management.
4. **Presentation Controller Separation**: `SongLoaderController` keeps the file-picking workflow out of `MainView`, which leaves the view focused on user interaction and navigation.
5. **Declarative Routing**: `MyApp` now uses `MaterialApp.router` with a centralized `GoRouter`, which standardizes route handling across the app and makes future deep-link support easier to add.
6. **Repository-Based File Access**: Song loading now flows through `SongRepository`, `SongFilePicker`, and `SongFileReader`, which keeps file selection and decoding out of the presentation layer and makes the data boundary easier to test.
7. **Rich Song Presentation**: The formatter/parser layer now understands ChordPro-style markup, transposition, and responsive two- or three-column song layouts for wide screens, while plain-text songs keep transpose controls disabled and reset to concert pitch.
8. **Feature-First Layout**: Related code now lives together under `lib/src/features/`, which makes the three app areas easier to navigate.
9. **Defensive Decoding**: File ingestion accounts for character encoding anomalies, preventing crashes on non-UTF-8 song files.
10. **High Automated Test Coverage**: Unit tests cover provider mutations and boundary conditions; widget tests validate multi-step interactive workflows, routing, scrolling actions, and chord transposition.

---

## 6. Architectural Weaknesses & Technical Debt

1. **Presentation Side Effects**
   - `MainView` still performs snackbar presentation and route triggering in response to controller state, which is acceptable for UI concerns but keeps some orchestration inline.

2. **Flat Route Tree**
   - The router is centralized, but the app currently uses a simple top-level route list; nested shells or route guards are not needed yet.
