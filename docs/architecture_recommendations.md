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

### Current Issue
The current structure groups files strictly by technical role (`models/`, `providers/`, `service/`, `views/`, `widgets/`). As features grow, navigation and maintenance across directories become fragmented.

### Proposed Solution
Adopt a feature-first structure with clear Separation of Concerns (Presentation / Domain / Data), as recommended by Flutter architecture guidelines:

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

---

## 4. Recommendation 3: Implement the Repository Pattern for File Access

### Current Issue
1. `FilePicker` is placed in `lib/widgets/file_picker_widget.dart` despite having no widget code.
2. It hardcodes a dependency on `filepicker_windows`, restricting the app from compiling or running on other platforms.
3. In `MainView`, button handlers directly orchestrate file dialogs, asynchronous I/O, error formatting, and navigation.

### Proposed Solution
1. Define an abstract `SongRepository` in the domain layer:

```dart
abstract class SongRepository {
  Future<SongFile?> pickSongFile();
  Future<Song> loadSong(SongFile file);
}
```

2. Implement platform-agnostic and Windows-specific data sources:
   - Use dependency injection to provide the appropriate picker implementation, or use a cross-platform package such as `file_picker`.

3. Decouple `Song` from `dart:io`:
   - Refactor `Song` so it does not contain a raw `dart:io File` handle.

---

## 5. Recommendation 4: Extract Presentation Logic to ViewModels / Controllers

### Current Issue
`MainView` contains inline logic for file picking, error handling, snackbars, and navigation.

### Proposed Solution
Extract this workflow into an `AsyncNotifier` or ViewModel that exposes state representing `idle`, `loading`, `success`, or `error`:

```dart
@riverpod
class SongLoaderController extends _$SongLoaderController {
  @override
  FutureOr<Song?> build() => null;

  Future<void> pickAndLoadSong() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(songRepositoryProvider);
      final file = await repository.pickSongFile();
      if (file == null) return null;
      return repository.loadSong(file);
    });
  }
}
```

`MainView` would call `ref.read(songLoaderControllerProvider.notifier).pickAndLoadSong()` and use `ref.listen` to handle snackbars or page transitions when `state.hasError` or `state.value != null`.

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
| **Phase 1** (High) | Relocate `FilePicker` from `widgets/` to `service/` or `data/` | Low | Medium | None |
| **Phase 1** (High) | Standardize route navigation across `MainView` and `main.dart` | Low | Medium | Low |
| **Phase 2** (Medium) | Introduce `SongRepository` and abstract platform file picker (`package:file_picker`) | Medium | High | Low |
| **Phase 2** (Medium) | Decouple `Song` domain model from `dart:io` | Low | Medium | Low |
| **Phase 2** (Medium) | Introduce `SongLoaderController` to remove business logic from `MainView` | Medium | High | Low |
| **Phase 3** (Long-term) | Transition to Feature-First directory structure (`lib/src/features/...`) | Medium | High | Medium |
| **Phase 3** (Long-term) | Add ChordPro parsing and chord transposition domain logic | High | High | Low |

