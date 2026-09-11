# Architectural Analysis of BandMole

> Documenting the current architectural design, components, data flows, and technical characteristics of the BandMole codebase.

---

## 1. Executive Summary

BandMole is a specialized Flutter desktop application developed for musicians to load, display, and smoothly auto-scroll song lyrics and chord charts. The codebase is organized around a small set of focused features: file selection and encoding validation, configurable auto-scrolling with transport playback controls, text customization (font size and speed), and persistent user themes.

The current architecture blends **Flutter Riverpod** state management, **Freezed** immutable data models, and Flutter widget lifecycle hooks with low-level platform plugins (`filepicker_windows`).

---

## 2. High-Level System Architecture

The application is structured into four primary vertical tiers:

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                      │
│   Views (MainView, SongView, PreferenceView)                │
│   Widgets (AutoScrollableTextWidget, Custom Tooltips)       │
└──────────────────────────────┬──────────────────────────────┘
                               │ Watches / Reads / Listens
┌──────────────────────────────▼──────────────────────────────┐
│                  State Management & Logic                    │
│   AutoScrollableTextNotifier (Notifier<AutoScrollableText>) │
│   AutoScrollableTextEvent (StreamNotifier<TextEvent>)       │
│   AppThemeNotifier (AsyncNotifier<ThemeData>)               │
└──────────────────────────────┬──────────────────────────────┘
                               │ Invokes / Consumes
┌──────────────────────────────▼──────────────────────────────┐
│                    Services & Infrastructure                │
│   PreferenceService (SharedPreferences)                     │
│   FileService (UTF-8 Decoder)                               │
│   AutoScrollableTextService (Broadcast StreamController)    │
│   FilePicker (filepicker_windows FFI Wrapper)               │
└──────────────────────────────┬──────────────────────────────┘
                               │ Produces / Operates on
┌──────────────────────────────▼──────────────────────────────┐
│                         Domain Models                       │
│   Song, AutoScrollableText (Freezed), AppTheme, TextEvent   │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Component Breakdown

### 3.1 Presentation Layer (`lib/views/` & `lib/widgets/`)

- **`MainView` (`lib/views/main_view.dart`)**:
  - The initial landing screen.
  - Hosts the file picker entry point (`Open song` button) and navigation action to preferences.
  - Contains imperative presentation logic: directly triggers `FilePicker().getFile()`, invokes asynchronous file reading via `getSong()`, validates encoding errors, and triggers `ScaffoldMessenger` snackbars.
  - Uses manual `Navigator.push` to transition to `SongView` and `PreferenceView`.

- **`SongView` (`lib/views/song_view.dart`)**:
  - The primary performance display.
  - Accepts raw song lyrics text via its constructor.
  - Wraps `AutoScrollableTextWidget` and provides floating action buttons for font size adjustment, scroll speed, start/stop scrolling, and boundary jumps ("Go to start", "Go to end").
  - Interacts with state via two distinct Riverpod channels:
    1. Reads `autoScrollableTextProvider.notifier` for font size, speed, and scroll toggle.
    2. Reads `autoScrollableTextEventProvider.notifier` to push transport jump events.

- **`PreferenceView` (`lib/views/preferences_view.dart`)**:
  - Displays a `ListView` of selectable color theme cards.
  - Dispatches theme selection changes directly to `appThemeProvider.notifier.setAppTheme()`.

- **`AutoScrollableTextWidget` (`lib/widgets/auto_scrollable_text_widget.dart`)**:
  - Core scroll rendering engine extending `ConsumerStatefulWidget` with `TickerProviderStateMixin`.
  - Manages a local `ScrollController` attached to a `SingleChildScrollView`.
  - Computes dynamic linear scroll durations based on `scrollSpeed`, `maxScrollExtent`, and current `offset`.
  - Subscribes to `autoScrollableTextEventProvider` for jump events and listens to `autoScrollableTextProvider` state updates to adjust active animations.
  - Intercepts scroll notifications via `NotificationListener<ScrollNotification>` to detect user touches and naturally completed scrolls.

- **Supporting Widgets (`lib/widgets/`)**:
  - `ToolTipRaisedButton`: A reusable elevated button wrapped in a `Tooltip`.
  - `ToolTipRoundedText`: A pill-shaped numeric display for font size and scroll speed.
  - `FilePicker` (*architectural misclassification*): Defined in `widgets/file_picker_widget.dart`, but is not a Flutter `Widget`; it wraps the Windows-native COM/Win32 file dialog.

---

### 3.2 State Management & Application Logic (`lib/providers/`)

State management is implemented using **Riverpod (v3.4+)**:

1. **`AutoScrollableTextNotifier` (`auto_scrollable_text_provider.dart`)**:
   - Manages the core reading session state encapsulated in the Freezed model `AutoScrollableText`.
   - Fields tracked: `isScrolling`, `isAtStart`, `isAtEnd`, `scrollSpeed` (1-99), `textFontSize` (min 8.0).
   - Manages state transformations (`increaseTextFontSize`, `decreaseTextFontSize`, `increaseScrollSpeed`, `decreaseScrollSpeed`, `toggleIsScrolling`, `setIsScrolling`, `resetScrollState`, `setPositionState`).
   - Defined via manual `NotifierProvider`.

2. **`AutoScrollableTextEvent` (`auto_scrollable_text_event_provider.dart`)**:
   - Implemented as a code-generated `StreamNotifierProvider` annotated with `@Riverpod(keepAlive: true)`.
   - Retains an instance of `AutoScrollableTextService`, exposing an event dispatch pipeline to broadcast jump commands (`TextEvent.goToStart`, `TextEvent.goToEnd`) across widgets without recreating controllers.

3. **`AppThemeNotifier` (`app_themes_provider.dart`)**:
   - Manages global theme state as an `AsyncNotifier<ThemeData>`.
   - Asynchronously loads persisted preferences from disk during `build()` and falls back to `AppTheme.blueDark`.
   - Persists updates to disk via `preference_service.dart`.

---

### 3.3 Data & Infrastructure Services (`lib/service/`)

- **`file_service.dart`**:
  - Provides `getSong(File)` to read raw file bytes and attempt strict UTF-8 decoding.
  - Employs a fallback decoding strategy with `allowMalformed: true` if strict decoding fails, marking `isMalformed: true` on the returned model.
- **`preference_service.dart`**:
  - Wraps `SharedPreferences` to load and save `themeData` by enum string representation.
- **`auto_scrollable_text_service.dart`**:
  - Encapsulates a broadcast `StreamController<TextEvent>` to manage event streaming between disjoint UI components.

---

### 3.4 Domain Models (`lib/models/`)

- **`Song` (`song.dart`)**:
  - Represents a loaded song file. Contains `file` (`dart:io File`), `text` (`String?`), and `isMalformed` (`bool`).
- **`AutoScrollableText` (`auto_scrollable_text.dart`)**:
  - An immutable Freezed value object representing the reading and scrolling state.
- **`AppTheme` (`app_themes.dart`)**:
  - An enum (`greenLight`, `greenDark`, `blueLight`, `blueDark`) paired with a global dictionary `appThemeData` mapping to standard Flutter `ThemeData` objects.
- **`TextEvent` (`text_event.dart`)**:
  - An enum defining commands for scrolling and transport navigation.

---

## 4. Key Data & Control Flows

### 4.1 Song Selection & Loading Flow
```
[User taps 'Open song']
       │
       ▼
MainView invokes FilePicker().getFile() (via Win32 native dialog)
       │
       ├── (File is null) ──► Show 'No song selected' SnackBar
       │
       └── (File selected)
              │
              ▼
       Calls getSong(file) in file_service.dart
              │
              ├── Decode bytes as UTF-8
              │   ├── Success: isMalformed = false
              │   └── Failure: Fallback with allowMalformed: true, isMalformed = true
              ▼
       MainView navigates to SongView(text: song.text)
```

### 4.2 Auto-Scroll Execution & Animation Flow
```
[User taps Play Icon]
       │
       ▼
SongView calls autoScrollableTextProvider.notifier.toggleIsScrolling()
       │
       ▼
Riverpod emits updated AutoScrollableText (isScrolling: true)
       │
       ▼
AutoScrollableTextWidget.ref.listen detects state change
       │
       ▼
Calculates duration = (maxScrollExtent - offset) / (speed * 10)
       │
       ▼
ScrollController.animateTo(maxScrollExtent, curve: Curves.linear)
       │
       ▼
Scroll notifications update setPositionState(screenOffset, screenMaxExtent)
       │
       ├── User manually touches / drags ──► setIsScrolling(false), halts animation
       ├── User taps Stop ───────────────► ScrollController.jumpTo(offset), setIsScrolling(false)
       └── Reaches bottom ───────────────► ScrollEndNotification triggers setIsScrolling(false)
```

### 4.3 Jump Navigation ("Go to start" / "Go to end") Flow
```
[User taps 'Go to end' / 'Go to start']
       │
       ▼
SongView dispatches TextEvent.goToEnd / goToStart via autoScrollableTextEventProvider
       │
       ▼
AutoScrollableTextService broadcast stream delivers event to AutoScrollableTextWidget
       │
       ▼
AutoScrollableTextWidget halts scrolling (setIsScrolling(false))
       │
       ▼
ScrollController animates to minScrollExtent or maxScrollExtent (1-second transition)
       │
       ▼
Post-frame callback triggers setPositionState to update isAtStart & isAtEnd flags
       │
       ▼
SongView rebuilds: appropriate button disables automatically
```

---

## 5. Architectural Strengths

1. **Reactive UI State Binding**: Core UI controls (font size, speed, play/pause state) cleanly subscribe to immutable state generated by Freezed through Riverpod.
2. **Robust Scroll Synchronization**: Uses post-frame callbacks and `ScrollNotification` listeners to ensure the Flutter framework does not mutate provider states during build phases.
3. **Resilient Stream Retention**: Event dispatching uses `@Riverpod(keepAlive: true)` to maintain long-lived stream channels, preventing stream closure and orphan subscriptions during view transitions.
4. **Defensive Decoding**: File ingestion accounts for character encoding anomalies, preventing crashes on non-UTF-8 song files.
5. **High Automated Test Coverage**: Unit tests cover provider mutations and boundary conditions; widget tests validate multi-step interactive workflows, routing, and scrolling actions.

---

## 6. Architectural Weaknesses & Technical Debt

1. **Dual-Channel State Architecture for Scrolling**:
   - Scrolling actions are divided between `AutoScrollableTextNotifier` (`NotifierProvider`) and `AutoScrollableTextEvent` (`StreamNotifierProvider` wrapping `StreamController`). This introduces unnecessary complexity when a unified controller or notifier pattern would suffice.
2. **Misplaced Service Component**:
   - `FilePicker` is located in `lib/widgets/file_picker_widget.dart` despite having no UI widget implementation.
3. **Platform Tight-Coupling**:
   - Direct dependence on `package:filepicker_windows` inside the codebase without an abstraction layer limits future expansion to mobile (iOS/Android), macOS, Linux, or Web.
4. **Direct Coupling of Domain Models to `dart:io`**:
   - `Song` directly retains a `dart:io File` reference, preventing the model from being shared in web builds or purely decoupled unit test environments.
5. **Business Logic in View Layer**:
   - `MainView` directly coordinates file picking, error handling, snackbars, and navigation, violating Separation of Concerns.
6. **Inconsistent Navigation Patterns**:
   - `main.dart` configures dynamic `onGenerateRoute` supporting `/`, `/lyrics`, and `/preferences`, but `MainView` bypasses this by constructing `MaterialPageRoute` directly with hardcoded widget constructors.
