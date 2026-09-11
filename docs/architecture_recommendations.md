# Architectural Recommendations for BandMole

> Strategic and technical recommendations to enhance modularity, maintainability, testability, and multi-platform readiness.

---

## 1. Overview & Objectives

While BandMole currently fulfills its core responsibilities with high test coverage and responsive controls, several structural and design patterns can be improved to align with Flutter industry best practices (specifically the **Layered Architecture: Presentation, Domain, Data** approach).

Key goals of these recommendations:
1. **Eliminate redundant state channels** between UI components.
2. **Decouple business and platform logic** from the widget layer.
3. **Abstract platform-specific dependencies** (`filepicker_windows`, `dart:io`) to enable multi-platform support (macOS, Linux, Android, iOS, Web).
4. **Transition to a feature-first, layered codebase organization**.

---

## 2. Recommendation 1: Unify Auto-Scroll State Management

### Current Issue
Scrolling logic is split across two disjoint Riverpod providers:
- `autoScrollableTextProvider` (`NotifierProvider`): Stores speed, font size, and boolean flags (`isScrolling`, `isAtStart`, `isAtEnd`).
- `autoScrollableTextEventProvider` (`StreamNotifierProvider` wrapping a `StreamController<TextEvent>`): Used exclusively to send jump commands (`goToStart`, `goToEnd`).

This dual-channel approach creates subtle lifecycle hazards, requires manual stream subscription management inside widgets, and bypasses Riverpod's standard reactive state flow.

### Proposed Solution
Consolidate scrolling interactions into a single cohesive presentation controller or use an explicit `ScrollController` bridge:

```
┌────────────────────────────────────────────────────────┐
│               Unified LyricsController                 │
│  - State: AutoScrollableText (speed, font, boundaries) │
│  - Commands: togglePlay(), jumpToStart(), jumpToEnd()  │
└───────────────────────────┬────────────────────────────┘
                            │
               ┌────────────┴────────────┐
               ▼                         ▼
         [SongView UI]       [AutoScrollableTextWidget]
```

#### Approach: Event/Command via Action State or Notifier Method
Instead of a separate stream provider, the `AutoScrollableTextNotifier` can expose target scroll offsets or explicit action signals, or `AutoScrollableTextWidget` can expose a controller callback registered with Riverpod:

```dart
// Enhanced AutoScrollableText state with scroll command trigger
@freezed
abstract class AutoScrollableText with _$AutoScrollableText {
  const factory AutoScrollableText({
    required bool isScrolling,
    required bool isAtEnd,
    required bool isAtStart,
    required int scrollSpeed,
    required double textFontSize,
    @Default(null) ScrollCommand? pendingCommand,
  }) = _AutoScrollableText;
}

enum ScrollCommand { jumpToStart, jumpToEnd }
```

When `jumpToStart()` is called, the notifier sets `pendingCommand = ScrollCommand.jumpToStart`. The widget's `ref.listen` consumes the command, animates, and calls `notifier.clearPendingCommand()`. This eliminates `AutoScrollableTextService`, `autoScrollableTextEventProvider`, and raw `StreamSubscription` lifecycle management.

---

## 3. Recommendation 2: Adopt a Feature-First Layered Project Structure

### Current Issue
The current structure groups files strictly by technical role (`models/`, `providers/`, `service/`, `views/`, `widgets/`). As features grow (e.g., adding chord transposing, setlists, cloud sync), navigation and maintenance across directories become fragmented.

### Proposed Solution
Adopt a **feature-first structure** with clear Separation of Concerns (**Presentation / Domain / Data**), as recommended by Flutter architecture guidelines:

```
lib/
├── src/
│   ├── app.dart                        # MaterialApp entry configuration
│   ├── core/                           # Shared cross-cutting components
│   │   ├── theme/                      # App themes & theme provider
│   │   ├── utils/                      # Encoding & text utilities
│   │   └── widgets/                    # Global reusable UI widgets
│   │       ├── tooltip_button.dart
│   │       └── rounded_badge.dart
│   └── features/
│       ├── lyrics_scroller/            # Lyrics display & scroller feature
│       │   ├── data/                   # Data sources & repositories
│       │   ├── domain/                 # Models (AutoScrollableText)
│       │   └── presentation/           # Views, widgets & Riverpod notifiers
│       │       ├── controllers/
│       │       ├── views/
│       │       └── widgets/
│       ├── song_loader/                # File selection & song parsing feature
│       │   ├── data/                   # File picker services & local storage
│       │   ├── domain/                 # Song domain model
│       │   └── presentation/           # MainView & song search controllers
│       └── preferences/                # User preferences feature
│           ├── data/                   # SharedPreferences repository
│           ├── domain/                 # AppTheme models
│           └── presentation/           # PreferencesView & controllers
```

---

## 4. Recommendation 3: Implement the Repository Pattern for File Access

### Current Issue
1. `FilePicker` is placed in `lib/widgets/file_picker_widget.dart` despite having no widget code.
2. It hardcodes a dependency on `filepicker_windows`, restricting the app from compiling or running on other platforms.
3. In `MainView`, button handlers directly orchestrate file dialogs, asynchronous I/O, error formatting, and navigation.

### Proposed Solution
1. **Define an abstract `SongRepository`** in the Domain layer:

```dart
abstract class SongRepository {
  Future<SongFile?> pickSongFile();
  Future<Song> loadSong(SongFile file);
}
```

2. **Implement Platform-Agnostic and Windows-Specific Data Sources**:
   - Use dependency injection to provide the appropriate picker implementation (or utilize cross-platform packages such as `file_picker` which handle Windows, macOS, Linux, iOS, Android, and Web seamlessly).

3. **Decouple `Song` Model from `dart:io`**:
   - Refactor `Song` so it does not contain a raw `dart:io File` handle:

```dart
@freezed
abstract class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String content,
    required bool isMalformed,
    String? sourcePath,
  }) = _Song;
}
```

---

## 5. Recommendation 4: Extract Presentation Logic to ViewModels / Controllers

### Current Issue
`MainView` contains inline logic:
```dart
onPressed: () async {
  final selectedFile = FilePicker().getFile();
  if (selectedFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  } else {
    final Song song = await getSong(selectedFile);
    ...
  }
}
```

### Proposed Solution
Extract this workflow into an `AsyncNotifier` (or ViewModel) that exposes state representing `idle`, `loading`, `success`, or `error`:

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

`MainView` simply calls `ref.read(songLoaderControllerProvider.notifier).pickAndLoadSong()` and uses `ref.listen` to handle snackbars or page transitions when `state.hasError` or `state.value != null`.

---

## 6. Recommendation 5: Standardize Declarative Navigation

### Current Issue
`main.dart` configures a named route map via `onGenerateRoute`, but views bypass this configuration by creating explicit `MaterialPageRoute` instances:
- `MainView` directly pushes `MaterialPageRoute(builder: (_) => const PreferenceView())`.
- `MainView` directly pushes `MaterialPageRoute(builder: (_) => SongView(text: song.text!))`.

### Proposed Solution
Adopt a single, consistent navigation paradigm:
- **Option A (Standard Flutter Navigator 2.0)**: Use `Navigator.pushNamed(context, '/lyrics', arguments: song.content)`.
- **Option B (Recommended for scalability)**: Adopt [GoRouter](https://pub.dev/packages/go_router) for declarative, type-safe routing, deep-linking, and cleaner parameter passing:

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
1. **ChordPro Support**: Add a parser for standard `[C] [G] [Am] [F]` ChordPro format.
2. **Key Transposition**: Allow real-time chord transposition up/down semitones.
3. **Multi-Column Layout**: Adapt layout on wide desktop screens to display lyrics side-by-side rather than a single tall column.

---

## 8. Summary & Implementation Roadmap

| Priority | Initiative | Effort | Impact | Risk |
|---|---|---|---|---|
| **Phase 1** (High) | Unify scrolling state into a single Riverpod notifier; eliminate `AutoScrollableTextService` & stream | Low | High | Low |
| **Phase 1** (High) | Relocate `FilePicker` from `widgets/` to `service/` or `data/` | Low | Medium | None |
| **Phase 1** (High) | Standardize route navigation across `MainView` and `main.dart` | Low | Medium | Low |
| **Phase 2** (Medium) | Introduce `SongRepository` and abstract platform file picker (`package:file_picker`) | Medium | High | Low |
| **Phase 2** (Medium) | Decouple `Song` domain model from `dart:io` | Low | Medium | Low |
| **Phase 2** (Medium) | Introduce `SongLoaderController` to remove business logic from `MainView` | Medium | High | Low |
| **Phase 3** (Long-term) | Transition to Feature-First directory structure (`lib/src/features/...`) | Medium | High | Medium |
| **Phase 3** (Long-term) | Add ChordPro parsing and chord transposition domain logic | High | High | Low |
