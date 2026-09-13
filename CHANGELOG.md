# Changelog

All notable changes to the BandMole project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Project Structure**:
  - Adopted a feature-first layered layout under `lib/src/` and moved the app into `core/` and `features/` folders for `lyrics_scroller`, `song_loader`, and `preferences`.
  - Removed the old top-level `models/`, `providers/`, `service/`, `views/`, and `widgets/` folders so the source tree now matches the layered architecture docs.

- **Song Loading / Repository Pattern**:
  - Introduced `SongRepository` as the domain boundary for file picking and file loading, with `SongFile` used as a platform-neutral file handle.
  - Split file access into `SongFilePicker`, `SongFileReader`, and `SongRepositoryImpl`, and moved the Windows picker behind a platform-specific implementation.
  - Refactored `MainView` to call the repository instead of directly orchestrating file dialogs, file reads, and decoding.
  - Updated `Song` so it no longer depends on `dart:io File`.
  - Added unit coverage for the repository implementation in `test/src/features/song_loader/data/song_repository_impl_test.dart`.

- **Auto Scrollable Text Module (`auto_scrollable_text`)**:
  - Unified jump navigation and scroll state into a single `AutoScrollableTextNotifier` flow by adding `pendingCommand` to the `AutoScrollableText` model and routing "Go to start" / "Go to end" through the same Riverpod state used for play, stop, font size, and speed controls.
  - Removed the separate event-stream style jump path from the architecture docs and aligned the README project structure with the current provider/model layout.
  - Kept the existing auto-scroll boundary and toggle behavior covered by the unit and widget tests in `test/auto_scrollable_text_test.dart` and `test/widget_test.dart`.

## [1.0.3] - 2026-09-11

### Fixed
- **Auto Scrollable Text Module (`auto_scrollable_text`)**:
  - Fixed issue where "Go to end" and "Go to start" buttons were non-functional because `autoScrollableTextEventProvider` was auto-disposed immediately after `initState()`, closing the underlying event `StreamController` and routing subsequent button actions to a newly instantiated, unlistened service stream.
  - Configured `@Riverpod(keepAlive: true)` on `AutoScrollableTextEvent` and regenerated provider bindings to ensure the broadcast event stream persists across the view lifecycle.
  - Fixed issue where triggering "Go to start" or "Go to end" while auto-scrolling did not cancel active scrolling, leaving `isScrolling: true` in an inconsistent state; both actions now explicitly reset scrolling (`setIsScrolling(false)`) and restore the play icon.
  - Refactored `_scrollToStart()` and `_scrollToEnd()` in `AutoScrollableTextWidget` to check boundary limits against `_scrollController.offset` directly.
  - Fixed Flutter Riverpod 3 `Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe` exception during widget unmount by caching `_textNotifier` during `initState()` instead of reading `ref` in `dispose()`.
  - Removed unused `auto_scrollable_text.dart` import from `AutoScrollableTextWidget`.

### Added
- Widget test in `test/widget_test.dart` verifying "Go to end" and "Go to start" buttons animate to boundaries and appropriately update button enabled/disabled states.
- Widget test in `test/widget_test.dart` verifying that "Go to start" stops an active auto-scrolling session and resets the scroll position to the top.

## [1.0.2] - 2026-08-30

### Fixed
- **Auto Scrollable Text Module (`auto_scrollable_text`)**:
  - Fixed issue where stopping the auto-scroll caused the view to pause briefly and then resume scrolling automatically due to a 1-second restart `Timer` triggered by `ScrollEndNotification`.
  - Replaced animated deceleration on stop with immediate `_scrollController.jumpTo(_scrollController.offset)`, halting active scroll animations instantaneously.
  - Removed restart `Timer` from `NotificationListener<ScrollNotification>` and added direct detection for natural scroll completion and user touch gestures.
  - Fixed issue where font size and scroll speed buttons only allowed a single step adjustment due to Riverpod `StreamNotifier` state deduplication dropping identical consecutive stream events.
  - Refactored `SongView` font size, scroll speed, and scrolling toggle actions to invoke `autoScrollableTextProvider.notifier` methods directly.
  - Updated `AutoScrollableTextWidget` to listen directly to `autoScrollableTextProvider` state changes for live animation adjustments when scroll speed or scrolling status changes.
  - Fixed issue where the play button remained inactive when opening a new song if a previously viewed song completed scrolling to the end.
  - Added `resetScrollState()` to `AutoScrollableTextNotifier` to reset scroll flags (`isScrolling: false`, `isAtStart: true`, `isAtEnd: false`) on song load while preserving custom `scrollSpeed` and `textFontSize` preferences.
  - Added post-frame layout validation in `AutoScrollableTextWidget` during initialization and widget rebuilds to automatically determine if a song is fully visible on screen (`maxScrollExtent <= 0.0`) or scrollable.
  - Added disposal cleanup in `AutoScrollableTextWidget` to cancel stream subscriptions and ensure scrolling is stopped when leaving the song view.

### Added
- Unit test in `test/auto_scrollable_text_test.dart` verifying that `resetScrollState()` resets boundary and scrolling flags without altering user-configured font size and scroll speed.
- Widget test in `test/widget_test.dart` verifying that font size and scroll speed can be repeatedly adjusted across multiple consecutive taps.
- Widget test in `test/widget_test.dart` verifying start and stop auto-scrolling toggle states.

## [1.0.1] - 2026-08-28

### Fixed
- **App Infrastructure & Routing (`main.dart`)**:
  - Added `WidgetsFlutterBinding.ensureInitialized()` in `main()` to guarantee binary messenger platform channel binding prior to asynchronous provider initialization.
  - Replaced static route map with dynamic `onGenerateRoute` handler, enabling argument extraction (`RouteSettings.arguments`) for `/lyrics` to pass song text dynamically to `SongView`.
  - Resolved theme loading flash by using `themeAsync.value ?? appThemeData[AppTheme.blueDark]!` fallback during initial load.

- **App Themes Module (`app_themes_provider`)**:
  - Fixed illegal Riverpod state mutation inside `AppThemeNotifier.build()`.
  - Refactored `setAppTheme` and `preference_service.dart` to operate on `AppTheme` enum directly, eliminating fragile `ThemeData` object identity (`==`) comparisons.
  - Made theme persistence asynchronous and awaited `SharedPreferences` disk operations.
  - Removed `autoDispose` from `appThemeProvider` to ensure global app theme persists across view transitions.

- **Auto Scrollable Text Module (`auto_scrollable_text`)**:
  - Fixed bug in `SongView` where pressing the "Decrease text font size" button mistakenly sent `TextEvent.decreaseScrollSpeed`.
  - Fixed double-toggling bug in `AutoScrollableTextWidget` when modifying scroll speed during an active scroll session.
  - Fixed single-subscription `StateError` in `AutoScrollableTextService` by making the event `StreamController` broadcast.
  - Added stream disposal via `ref.onDispose` in `autoScrollableTextEventProvider` to eliminate memory leaks.
  - Added state equality guards in `AutoScrollableTextNotifier.setPositionState` to prevent unnecessary widget rebuilds on every pixel scroll.
  - Deferred scroll notification state updates using `addPostFrameCallback` to prevent Flutter build phase state mutation errors.
  - Added `ScrollController.hasClients` and non-zero duration guards across all scrolling animation logic.

- **Refactoring & Package Dependencies**:
  - Fixed file and class name typos (`auto_scollable` -> `auto_scrollable`).
  - Corrected `freezed_annotation` (`dependencies`) and `freezed` (`dev_dependencies`) placement in `pubspec.yaml` for Freezed 4 compatibility.
  - Updated `AutoScrollableText` freezed model definition to use `abstract class`.

### Added
- Comprehensive unit tests for `appThemeProvider` in `test/app_themes_provider_test.dart`.
- Unit tests for `AutoScrollableTextNotifier` bounds, font size, speed limits, and position state handling in `test/auto_scrollable_text_test.dart`.
- Widget tests for `MyApp` initial routing, `SongView`, and `PreferenceView` UI components in `test/widget_test.dart`.
