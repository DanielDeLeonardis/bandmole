# Release 3 Cross-Cutting Technical Debt & Final Review

> Status: Implemented and resolved on desktop (Windows verified); Android 10+ device verification (R3-TD-01) and the temporary Windows `ExcludeSemantics` workaround for upstream Flutter engine bugs (R3-TD-06) remain tracked below. Updated on 2026-11-27.

This register records the final review of Release 3 (ChordPro Editor) across functionality, architecture, platform support, ChordPro 6.101 compliance, accessibility, and test verification.

---

## Current Verification Baseline

| Check | Result | Notes |
| --- | --- | --- |
| `dart analyze` | Pass | 0 issues |
| `flutter test --coverage --branch-coverage` | Pass | 147 unit & widget tests passing across all features and routing |
| `dart run tool/check_coverage.dart` | Pass | `song_loader` 81.3%, `lyrics_scroller` 87.3%, `preferences` 90.0%, `song_groups` 81.6%, `chordpro_editor` 88.0%, `navigation` 100.0% (all ≥ 80%) |
| `flutter test integration_test/release_3_workflow_test.dart -d windows` | Pass | Exercises `MyApp` → `MainView` → read-only `.txt` → Convert → keyboard section reorder → SQLite custom directives → `Ctrl+S` save → `Esc` close → gig broken-link sync → `scroll_speed` reload → explicit Overwrite confirmation |

---

## Resolved Findings

### R3-TD-02: Editor preferences and global custom directives now use a repository boundary backed by SQLite

Resolved. Extracted `ChordProPreferencesRepository` in `lib/src/features/chordpro_editor/domain/chordpro_preferences_repository.dart` with `SqliteChordProPreferencesRepository` (persisting global custom directives in a native SQLite `custom_directives` table with one-time migration from legacy `SharedPreferences`, and managing `hintDismissed`), a `SharedPreferencesChordProPreferencesRepository` web/fallback implementation, and conditional Riverpod providers (`chordpro_preferences_provider*.dart`). `ChordProEditorView` no longer imports `SharedPreferences` directly. Covered by `test/src/features/chordpro_editor/data/sqlite_chordpro_preferences_repository_test.dart`.

### R3-TD-03: `ChordProSongStore` now uses a platform-neutral domain contract with conditional IO/stub providers

Resolved. Moved `ChordProSongStore`, `ChordProSaveException`, and `ChordProSaveErrorCode` to pure Dart in `lib/src/features/chordpro_editor/domain/chordpro_song_store.dart`, moved the native filesystem + Android SAF implementation to `lib/src/features/chordpro_editor/data/io_chordpro_song_store.dart`, added `UnsupportedChordProSongStore` for non-IO targets, and wired `chordpro_song_store_provider*.dart`. `ChordProEditorView` has no `dart:io` imports.

### R3-TD-04: `ChordProEditorView` split into modular presentation widgets

Resolved. Extracted `chordpro_editor_dialogs.dart` (`CustomChordDialog`, `CustomDirectiveDialog`, `OverwriteFileDialog`, `UnsavedChangesDialog`), `chordpro_palettes.dart` (`ChordProChordPalette`, `ChordProDirectivePalette`), and `chordpro_outline_panel.dart` (`ChordProOutlinePanel`), keeping `ChordProEditorView` focused on editor coordination.

### R3-TD-05: Renderer labels localized and additional ChordPro 6.101 semantics implemented

Resolved for Release 3 scope. Routed app-generated metadata chip labels (`Key`, `Capo`, `Artist`, `Album`, `Year`, `Composer`, `Lyricist`, `Arranger`, `Tempo`, `Time`, `Duration`) and default section labels (`Verse`, `Chorus`, `Bridge`, `Intro`, `Outro`, `Tab`, `Grid`) in `SongTextRenderer` through `AppLocalizations` while keeping user-authored labels and song content completely untouched. Added `%{meta}` variable interpolation, transposed inline `{chord}` labels, mid-song scoped chord style overrides (`chordfont`/`chordsize`/`chordcolour`), and conversion ambiguity notifications (`ChordProDocument.convertDetailed`). Instrument-profile conditional directive filtering (e.g., `{define-ukulele: ...}`) remains deferred to Release 4 when instrument selection is introduced.

### R3-TD-07: Desktop integration tests cover keyboard actions, SQLite directive persistence, and gig broken-link sync

Resolved on Windows. `MainView._openEditor` now re-validates loaded gigs against the refreshed library after saving a song so creating a missing `.chopro` clears its broken link immediately. `integration_test/release_3_workflow_test.dart` now verifies keyboard shortcuts (`Ctrl+S`, `Esc`), keyboard-accessible outline reordering, SQLite custom-directive and hint-dismissal persistence across repository reopen, and gig broken-link clearing.

### R3-TD-08: Shared routing coverage added to gate and store error paths covered

Resolved. Added `navigation` (`lib/src/navigation/`) to `tool/check_coverage.dart` with router tests for `/lyrics` (`scroll_speed` on ChordPro vs plain text) and `/editor`, and added injectable atomic-rename tests for `IoChordProSongStore` fallback and cleanup paths.

### R3-TD-09: Added `.gitattributes` for consistent cross-platform line endings

Resolved. Added `.gitattributes` at the repository root to standardize LF line endings for source files (with CRLF for Windows `.bat`/`.cmd`/`.ps1` scripts and binary markers for media/archives).

---

## Remaining External / Platform-Verification Items

### R3-TD-01: Android 10+ SAF write workflow requires physical/emulated device verification

**Priority:** P1 — external device verification open

`MainActivity.kt` (`writeSong`) and `AndroidSafLibrary.writeSong` use `"application/octet-stream"` (avoiding `.chopro.txt`), support explicit overwrite reuse of existing document URIs, fall back from `"wt"` to `"w"`, guard nullable cursor columns, and map `EXISTS`/`PERMISSION` errors to `ChordProSaveException`. These paths are covered by mocked MethodChannel tests (`android_saf_library_test.dart`, `chordpro_song_store_test.dart`), but still require verification on a physical or emulated Android 10+ device (including upgrading a legacy Release 1/2 read-only SAF grant).

### R3-TD-06: Windows root `ExcludeSemantics` workaround for Flutter `accessibility_bridge.cc`

**Priority:** P2 — upstream Flutter engine workaround tied to deferred screen-reader support

To prevent Flutter `3.47.1`'s Windows Chromium accessibility bridge from logging `[ERROR:flutter/shell/platform/common/accessibility_bridge.cc(114)] Failed to update ui::AXTree, error: <id> will not be in the tree and is not the new root` (upstream Flutter `#100610` / `#182444`), [app.dart](../lib/src/app.dart) wraps `MaterialApp.router` in `ExcludeSemantics` on Windows (`!kIsWeb && defaultTargetPlatform == TargetPlatform.windows`). Keyboard-only navigation, text editing, visual tooltips, and drag-and-drop are unaffected. Remove this wrapper and re-verify with Windows UIA/Narrator once upgrading to a Flutter SDK that fixes the upstream bridge issue and implementing screen-reader support.

---

## Verified or Deferred Requirements

- **Offline-first operation:** All Release 3 editing, previewing, outlining, conversion, and saving workflows operate fully offline.
- **Single-column performance scrolling:** `AutoScrollableTextWidget` intentionally uses `allowMultiColumnLayout: false` because multi-column layout only works well when a song fits on one screen.
- **Linux, Web, iOS, and macOS:** Next/aspirational platforms per [requirements.md](requirements.md).
- **Releases 4–6 (Song Charts, Metadata, Data Import/Export):** Planned product work.
