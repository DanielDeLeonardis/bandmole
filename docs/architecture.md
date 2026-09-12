# Architectural Analysis of BandMole

> Documenting the current architectural design, components, data flows, and technical characteristics of the BandMole codebase.

---

## 1. Executive Summary

BandMole is a specialized Flutter desktop application for loading, displaying, and smoothly auto-scrolling song lyrics and chord charts. The codebase is organized around a small set of focused features: file selection and encoding validation, configurable auto-scrolling with transport playback controls, text customization, and persistent user themes.

The current architecture blends Flutter Riverpod state management, Freezed immutable data models, and Flutter widget lifecycle hooks with low-level platform plugins such as `filepicker_windows`.

One important architectural change is that auto-scroll jump actions are now unified into a single `AutoScrollableTextNotifier` flow. Instead of a separate event stream, jump navigation is represented as a one-shot `pendingCommand` on the shared `AutoScrollableText` state.

The codebase is now organized in a feature-first structure under `lib/src/` with shared UI helpers in `core/` and feature folders for `lyrics_scroller`, `preferences`, and `song_loader`.

---

## 2. High-Level System Architecture

The application is structured into four primary vertical tiers:

```text
Presentation Layer
  - Views: MainView, SongView, PreferenceView
  - Widgets: AutoScrollableTextWidget, custom tooltip widgets
  - Reads and writes Riverpod state

State Management & Logic
  - AutoScrollableTextNotifier (Notifier<AutoScrollableText>)
  - AppThemeNotifier (AsyncNotifier<ThemeData>)

Services & Infrastructure
  - PreferenceService (SharedPreferences)
  - FileService (UTF-8 decoding)
  - FilePicker (filepicker_windows wrapper)

Domain Models
  - Song, AutoScrollableText (Freezed), AppTheme
```

---

## 3. Detailed Component Breakdown

### 3.1 Presentation Layer (`lib/src/features/.../presentation/`)

- **`MainView` (`lib/src/features/song_loader/presentation/views/main_view.dart`)**
  - The initial landing screen.
  - Hosts the file picker entry point (`Open song`) and navigation action to preferences.
  - Contains imperative presentation logic: directly triggers `FilePicker().getFile()`, invokes asynchronous file reading via `getSong()`, validates encoding errors, and triggers `ScaffoldMessenger` snackbars.
  - Uses manual `Navigator.push` to transition to `SongView` and `PreferenceView`.

- **`SongView` (`lib/src/features/lyrics_scroller/presentation/views/song_view.dart`)**
  - The primary performance display.
  - Accepts raw song lyrics text via its constructor.
  - Wraps `AutoScrollableTextWidget` and provides floating action buttons for font size adjustment, scroll speed, start/stop scrolling, and boundary jumps (`Go to start`, `Go to end`).
  - Interacts with state through a single Riverpod notifier:
    - Reads `autoScrollableTextProvider` for font size, speed, scroll toggle, and boundary flags.
    - Dispatches all scroll-related actions via `autoScrollableTextProvider.notifier`.

- **`PreferenceView` (`lib/src/features/preferences/presentation/views/preferences_view.dart`)**
  - Displays a `ListView` of selectable color theme cards.
  - Dispatches theme selection changes directly to `appThemeProvider.notifier.setAppTheme()`.

- **`AutoScrollableTextWidget` (`lib/src/features/lyrics_scroller/presentation/widgets/auto_scrollable_text_widget.dart`)**
  - Core scroll rendering engine extending `ConsumerStatefulWidget` with `TickerProviderStateMixin`.
  - Manages a local `ScrollController` attached to a `SingleChildScrollView`.
  - Computes dynamic linear scroll durations based on `scrollSpeed`, `maxScrollExtent`, and current `offset`.
  - Listens to `autoScrollableTextProvider` state updates, including `pendingCommand`, to adjust active animations and handle jump requests.
  - Intercepts scroll notifications via `NotificationListener<ScrollNotification>` to detect user touches and naturally completed scrolls.

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

---

### 3.3 Data & Infrastructure Services (`lib/src/features/.../data/`)

- **`file_service.dart`**
  - Provides `getSong(File)` to read raw file bytes and attempt strict UTF-8 decoding.
  - Employs a fallback decoding strategy with `allowMalformed: true` if strict decoding fails, marking `isMalformed: true` on the returned model.

- **`preference_service.dart`**
  - Wraps `SharedPreferences` to load and save `themeData` by enum string representation.

The former auto-scroll stream service is no longer part of the current implementation. Jump navigation is now carried by the shared notifier state rather than a separate `StreamController`.

---

### 3.4 Domain Models (`lib/src/features/.../domain/`)

- **`Song` (`song.dart`)**
  - Represents a loaded song file.
  - Contains `file` (`dart:io File`), `text` (`String?`), and `isMalformed` (`bool`).

- **`AutoScrollableText` (`auto_scrollable_text.dart`)**
  - An immutable Freezed value object representing reading and scrolling state.
  - Includes `pendingCommand` so jump navigation can be expressed as part of the same state object that stores scrolling flags and user preferences.

- **`AppTheme` (`app_themes.dart`)**
  - An enum (`greenLight`, `greenDark`, `blueLight`, `blueDark`) paired with a global dictionary `appThemeData` mapping to standard Flutter `ThemeData` objects.

---

## 4. Key Data & Control Flows

### 4.1 Song Selection & Loading Flow

```text
[User taps 'Open song']
  -> MainView invokes FilePicker().getFile() via the Windows dialog
  -> If no file is selected, show a 'No song selected' SnackBar
  -> If a file is selected, call getSong(file) in file_service.dart
  -> Decode bytes as UTF-8
     - Success: isMalformed = false
     - Failure: fallback with allowMalformed = true, isMalformed = true
  -> MainView navigates to SongView(text: song.text)
```

### 4.2 Auto-Scroll Execution & Animation Flow

```text
[User taps Play Icon]
  -> SongView calls autoScrollableTextProvider.notifier.toggleIsScrolling()
  -> Riverpod emits updated AutoScrollableText (isScrolling: true)
  -> AutoScrollableTextWidget.ref.listen detects state change
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
  -> AutoScrollableTextWidget.ref.listen consumes pendingCommand and clears it
  -> AutoScrollableTextWidget animates to minScrollExtent or maxScrollExtent
  -> Post-frame callback triggers setPositionState to update isAtStart and isAtEnd
  -> SongView rebuilds and the appropriate button disables automatically
```

---

## 5. Architectural Strengths

1. **Reactive UI State Binding**: Core UI controls subscribe to immutable state generated by Freezed through Riverpod.
2. **Robust Scroll Synchronization**: Post-frame callbacks and `ScrollNotification` listeners help avoid mutating provider state during Flutter build phases.
3. **Unified Command State**: Jump navigation now uses the same notifier and model as the rest of the scroll controls, which keeps state transitions easier to follow and avoids stream lifecycle management.
4. **Feature-First Layout**: Related code now lives together under `lib/src/features/`, which makes the three app areas easier to navigate.
5. **Defensive Decoding**: File ingestion accounts for character encoding anomalies, preventing crashes on non-UTF-8 song files.
6. **High Automated Test Coverage**: Unit tests cover provider mutations and boundary conditions; widget tests validate multi-step interactive workflows, routing, and scrolling actions.

---

## 6. Architectural Weaknesses & Technical Debt

1. **Platform Tight-Coupling**
   - Direct dependence on `package:filepicker_windows` inside the codebase without an abstraction layer limits future expansion to mobile platforms, macOS, Linux, or Web.

2. **Direct Coupling of Domain Models to `dart:io`**
   - `Song` directly retains a `dart:io File` reference, preventing the model from being shared in web builds or purely decoupled unit test environments.

3. **Business Logic in View Layer**
   - `MainView` directly coordinates file picking, error handling, snackbars, and navigation, violating Separation of Concerns.

4. **Inconsistent Navigation Patterns**
   - `main.dart` configures dynamic `onGenerateRoute` supporting `/`, `/lyrics`, and `/preferences`, but `MainView` bypasses this by constructing `MaterialPageRoute` directly with hardcoded widget constructors.

