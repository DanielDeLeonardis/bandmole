# Architectural Recommendations for BandMole

> Strategic and technical recommendations to enhance modularity, maintainability, testability, and multi-platform readiness.

---

## 1. Overview & Objectives

While BandMole currently fulfills its prototype responsibilities with responsive controls, several structural and design patterns can be improved to align with Flutter industry best practices and the six-release product requirements, especially the layered Presentation / Domain / Data approach.

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
The same layout-driven boundary state now refreshes after viewport resize events so the scroll speed buttons stay aligned with whether the song currently fits on screen.

### Flow
The `AutoScrollableTextNotifier` exposes scroll commands directly, while `AutoScrollableTextWidget` listens for state changes and consumes `pendingCommand` when a jump is requested:

```text
+--------------------------------------------------+
| Unified Auto-Scroll State                        |
| - State: AutoScrollableText                      |
|   (speed, font, boundaries, pendingCommand)      |
| - Commands: toggleIsScrolling(), jumpToStart(), jumpToEnd() |
+--------------------------------------------------+
                         |
            +------------+-------------+
            |                          |
       [SongView UI]       [AutoScrollableTextWidget]
```

### Implementation Note
When `jumpToStart()` is called, the notifier sets `pendingCommand = ScrollCommand.jumpToStart`. The widget's manual listener consumes the command, animates, and calls `notifier.clearPendingCommand()`. This eliminates `AutoScrollableTextService`, `autoScrollableTextEventProvider`, and raw `StreamSubscription` lifecycle management.
`AutoScrollableTextWidget` also observes viewport metric changes and re-runs its boundary check after the next frame, which keeps the start/end flags and related button state current if the window is resized.

---

## 3. Recommendation 2: Adopt a Feature-First Layered Project Structure

### Status
Implemented in the current codebase.

### Result
The current prototype lives under a feature-first tree in `lib/src/`; planned release boundaries should extend this structure for the Songs Panel, Song Groups, ChordPro Editor, Song Charts, Metadata, and Data Import and Export:

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
- `SongFile` stores the selected file path and any platform-specific access capability without exposing `dart:io File`.
- `SongFile` also exposes extension-based ChordPro detection so the UI can gate transposition behavior on the loaded source type.
- The current prototype `SongRepository` exposes `pickSongFile()` and `loadSong(SongFile)`; the target library API should add root-directory selection, recursive refresh, warning reporting, and broken-reference relinking.

The data layer now provides platform-specific implementations behind the repository, and the target design should extend this boundary to directory access and persisted platform capabilities:
- `WindowsSongFilePicker` wraps `filepicker_windows`.
- Android and Web implementations should use platform-appropriate directory pickers and persist permissions or handles where supported.
- Capability-specific fallbacks should report unavailable access clearly rather than treating required platforms as unsupported.
- `IoSongFileReader` reads the selected file bytes for decoding.

`MainView` now only reacts to controller outcomes:
- dispatches the button tap to `SongLoaderController`,
- show a snackbar when no file is selected,
- show a snackbar when the file has encoding issues,
- reset transpose state for plain-text songs and navigate to `SongView` when the song text is loaded successfully.

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

Target library flow:
  -> SongRepository.selectRootDirectory()
  -> SongRepository.refreshLibrary()
  -> SongRepository.relinkSongReference()
```

`MainView` now stays focused on layout while a dedicated `SongLoaderEffectsListener` reacts to controller state changes:
- show a snackbar when the repository reports no file selected,
- show a snackbar when the file is malformed or cannot be loaded,
- navigate to `SongView` when a song loads successfully.

To keep those reactions lifecycle-safe, the listener defers snackbars and navigation to post-frame callbacks. The lyrics scroller follows the same pattern for scroll commands and state cleanup, which avoids mutating Riverpod state or looking up ancestors from a deactivated context.
The lyrics view also disables transpose controls for plain-text files and resets the transpose offset to zero when a non-ChordPro song is opened.

---

## 6. Recommendation 5: Standardize Declarative Navigation

### Current Issue
`main.dart` previously configured a named route map via `onGenerateRoute`, but views bypassed that router by creating explicit `MaterialPageRoute` instances.

### Proposed Solution
Implemented in the current codebase.

### Result
The app now uses `GoRouter` through `MaterialApp.router` with a centralized route tree:

```text
MyApp
  -> MaterialApp.router
  -> appRouterProvider
      -> GoRoute(name: main, path: /)
          -> GoRoute(name: lyrics, path: lyrics)
          -> GoRoute(name: preferences, path: preferences)
```

Navigation now uses declarative named routes consistently:
- `MainView` opens preferences with `context.pushNamed(AppRoutes.preferences)`.
- `MainView` opens lyrics with `context.pushNamed(AppRoutes.lyrics, extra: song)`.
- `GoRouter` builds `MainView`, `SongView`, and `PreferenceView` from one central route tree, while the lyrics route now rejects requests that do not include a `Song` payload.

---

## 7. Recommendation 6: Rich Chord & Song Formatting Enhancements

### Status
Implemented in the current codebase.

### Result
BandMole now parses chord charts into a richer presentation model before rendering them:
- `SongFormatter` turns plain lyrics or ChordPro-style source text into structured sections, lyric lines, chord markers, and song metadata.
- `SongTransposeNotifier` lets the view shift chords up or down semitones and reset to concert pitch, while `MainView` and `SongView` keep that control disabled for plain-text songs.
- `SongTextRenderer` keeps the lyric view responsive by rendering a single-column layout on narrow screens and a two- or three-column layout on wide desktop windows.

This keeps the formatting logic out of the widget tree while still giving musicians a more expressive chord sheet experience.

---

## 8. Recommendation 7: Isolate Song-Loader Side Effects

### Status
Implemented in the current codebase.

### Result
`MainView` now stays focused on composition, while a dedicated `SongLoaderEffectsListener` owns the transient snackbars and route changes triggered by `SongLoaderController` state.

That separation keeps the page layout easier to read and makes the effect handling reusable if another screen ever needs to respond to the same loader state:

```text
MainView
  -> SongLoaderEffectsListener
  -> songLoaderControllerProvider
  -> snackbars + lyrics navigation
```

The listener still performs the UI reactions in the presentation layer, but the orchestration is no longer embedded directly inside the page widget.

---

## 9. Recommendation 8: Nest Route Ownership and Guard the Song Payload

### Status
Implemented in the current codebase.

### Result
The router now groups feature routes beneath the main app route instead of keeping every destination in one flat top-level list.

`lyrics` is also guarded so it only opens when a `Song` payload is present:

```text
GoRoute(path: '/')
  -> MainView
  -> GoRoute(path: 'lyrics')
      -> requires Song extra
      -> SongView
  -> GoRoute(path: 'preferences')
      -> PreferenceView
```

This keeps route ownership clearer, gives the lyrics page a basic payload guard, and leaves room for future shells or redirects without changing the public navigation API.

---

## 10. Summary & Implementation Roadmap

| Priority | Initiative | Effort | Impact | Risk |
|---|---|---|---|---|
| **Completed** | Unified scrolling state into a single Riverpod notifier; removed the stream-based jump path | Low | High | Low |
| **Completed** | Transitioned to a feature-first directory structure (`lib/src/features/...`) | Medium | High | Medium |
| **Completed** | Relocated `FilePicker` into the `song_loader` feature data layer | Low | Medium | None |
| **Completed** | Standardize route navigation across `MainView` and `main.dart` with `GoRouter` | Low | Medium | Low |
| **Completed** | Introduce `SongRepository`, abstract platform file picker, and decouple `Song` from `dart:io` | Medium | High | Low |
| **Completed** | Introduce `SongLoaderController` to remove business logic from `MainView` | Medium | High | Low |
| **Completed** | Add ChordPro parsing, chord transposition, and responsive wide-screen song layout | Medium | High | Medium |
| **Completed** | Extract song-loader side effects into a dedicated listener widget | Low | Medium | Low |
| **Completed** | Nest lyrics/preferences routes beneath the main route and guard lyrics payloads | Low | Medium | Low |
