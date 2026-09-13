# Architectural Recommendations for BandMole

> Strategic and technical recommendations to enhance modularity, maintainability, testability, and multi-platform readiness.

---

## 1. Overview & Objectives

While BandMole currently fulfills its core responsibilities with high test coverage and responsive controls, several structural and design patterns can be improved to align with Flutter industry best practices, especially the layered Presentation / Domain / Data approach.

Key goals of these recommendations:
1. Eliminate redundant state channels between UI components.
2. Decouple business and platform logic from the widget layer.
3. Abstract platform-specific dependencies (`filepicker_windows`, `dart:io`) to enable multi-platform support.
4. Transition to a feature-first, layered codebase organization.

---

## 2. Recommendation 1: Unify Auto-Scroll State Management

### Status
Implemented in the current codebase.

### Result
Scrolling interactions now flow through a single Riverpod notifier:
- `autoScrollableTextProvider` (`NotifierProvider`): stores scroll speed, font size, boundary flags (`isScrolling`, `isAtStart`, `isAtEnd`), and one-shot jump commands via `pendingCommand`.

This removes the separate event-stream jump path, avoids manual stream subscription management inside widgets, and keeps jump navigation in the same reactive state flow as the rest of the scroll controls.

### Current Flow
The `AutoScrollableTextNotifier` exposes scroll commands directly, while `AutoScrollableTextWidget` listens for state changes and consumes `pendingCommand` when a jump is requested:

```text
+--------------------------------------------------+
| Unified LyricsController                         |
| - State: AutoScrollableText                      |
|   (speed, font, boundaries, pendingCommand)      |
| - Commands: togglePlay(), jumpToStart(), jumpToEnd() |
+--------------------------------------------------+
                         |
            +------------+-------------+
            |                          |
       [SongView UI]       [AutoScrollableTextWidget]
```

### Implementation Note
When `jumpToStart()` is called, the notifier sets `pendingCommand = ScrollCommand.jumpToStart`. The widget's `ref.listen` consumes the command, animates, and calls `notifier.clearPendingCommand()`. This eliminates `AutoScrollableTextService`, `autoScrollableTextEventProvider`, and raw `StreamSubscription` lifecycle management.

---

## 3. Recommendation 2: Adopt a Feature-First Layered Project Structure

### Status
Implemented in the current codebase.

### Result
The application now lives under a feature-first tree in `lib/src/`:

```text
lib/
|-- src/
|   |-- app.dart
|   |-- core/
|   |   |-- theme/
|   |   |-- utils/
|   |   `-- widgets/
|   `-- features/
|       |-- lyrics_scroller/
|       |   |-- data/
|       |   |-- domain/
|       |   `-- presentation/
|       |-- song_loader/
|       |   |-- data/
|       |   |-- domain/
|       |   `-- presentation/
|       `-- preferences/
|           |-- data/
|           |-- domain/
|           `-- presentation/
```

The old top-level `models/`, `providers/`, `service/`, `views/`, and `widgets/` folders have been removed.

---

## 4. Recommendation 3: Implement the Repository Pattern for File Access

### Current Issue
Before the refactor, the file picker hardcoded a dependency on `filepicker_windows`, and `MainView` directly orchestrated file dialogs, asynchronous I/O, error formatting, and navigation.

### Proposed Solution
Implemented in the current codebase.

### Result
The song-loading flow now goes through a repository boundary and a presentation controller instead of calling platform APIs directly from the view layer:

```text
MainView
  -> SongLoaderController
  -> SongRepository
      -> SongFilePicker
      -> SongFileReader
```

The domain layer now owns a platform-neutral file model:
- `SongFile` stores the selected file path without exposing `dart:io File`.
- `SongRepository` exposes `pickSongFile()` and `loadSong(SongFile)` as the only public file-access operations.

The data layer now provides platform-specific implementations behind the repository:
- `WindowsSongFilePicker` wraps `filepicker_windows`.
- `UnsupportedSongFilePicker` allows non-Windows builds to compile and fail gracefully at runtime.
- `IoSongFileReader` reads the selected file bytes for decoding.

`MainView` now only reacts to controller outcomes:
- dispatches the button tap to `SongLoaderController`,
- show a snackbar when no file is selected,
- show a snackbar when the file has encoding issues,
- navigate to `SongView` when the song text is loaded successfully.

---

## 5. Recommendation 4: Extract Presentation Logic to ViewModels / Controllers

### Current Issue
`MainView` previously contained inline logic for file picking, error handling, snackbars, and navigation.

### Proposed Solution
Implemented in the current codebase.

### Result
The song-loading workflow now lives in `SongLoaderController` as an `AsyncNotifier<Song?>`:

```text
MainView
  -> SongLoaderController.pickAndLoadSong()
      -> SongRepository.pickSongFile()
      -> SongRepository.loadSong(file)
```

`MainView` now reacts to controller state changes with `ref.listen`:
- show a snackbar when the repository reports no file selected,
- show a snackbar when the file is malformed or cannot be loaded,
- navigate to `SongView` when a song loads successfully.

---

## 6. Recommendation 5: Standardize Declarative Navigation

### Current Issue
`main.dart` configures a named route map via `onGenerateRoute`, but views bypass this configuration by creating explicit `MaterialPageRoute` instances.

### Proposed Solution
Adopt a single, consistent navigation paradigm:
- Option A: Use `Navigator.pushNamed(context, '/lyrics', arguments: song.content)`.
- Option B: Adopt `GoRouter` for declarative, type-safe routing, deep-linking, and cleaner parameter passing.

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainView(),
      ),
      GoRoute(
        path: '/lyrics',
        builder: (context, state) {
          final song = state.extra as Song;
          return SongView(song: song);
        },
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const PreferenceView(),
      ),
    ],
  );
});
```

---

## 7. Recommendation 6: Rich Chord & Song Formatting Enhancements

As a lyrics reader for musicians, BandMole's domain capabilities can be extended:
1. Add a parser for standard ChordPro format.
2. Allow real-time chord transposition up or down semitones.
3. Adapt layout on wide desktop screens to display lyrics side-by-side rather than a single tall column.

---

## 8. Summary & Implementation Roadmap

| Priority | Initiative | Effort | Impact | Risk |
|---|---|---|---|---|
| **Completed** | Unified scrolling state into a single Riverpod notifier; removed the stream-based jump path | Low | High | Low |
| **Completed** | Transitioned to a feature-first directory structure (`lib/src/features/...`) | Medium | High | Medium |
| **Completed** | Relocated `FilePicker` into the `song_loader` feature data layer | Low | Medium | None |
| **Phase 1** (High) | Standardize route navigation across `MainView` and `main.dart` | Low | Medium | Low |
| **Completed** | Introduce `SongRepository`, abstract platform file picker, and decouple `Song` from `dart:io` | Medium | High | Low |
| **Completed** | Introduce `SongLoaderController` to remove business logic from `MainView` | Medium | High | Low |
| **Phase 3** (Long-term) | Add ChordPro parsing and chord transposition domain logic | High | High | Low |
