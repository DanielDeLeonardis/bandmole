# Release 2 Cross-Cutting Technical Debt

> Status: Implemented in code. Reviewed against the Cross-Cutting Technical Requirements on 2026-10-16.

This register now reflects the Release 2 gaps that have been closed in the codebase. The branch-coverage gate remains part of CI, so the exact percentage should always come from the latest run rather than this note.

## Resolved Findings

### R2-TD-01: Native gig data is stored in SQLite

Resolved. `gigRepositoryProvider` now returns `SqliteGigRepository`, which stores gigs transactionally in SQLite, uses a versioned schema, and migrates legacy JSON from `bandmole_gigs_store`. Repository coverage lives in `test/src/features/song_groups/data/sqlite_gig_repository_test.dart`.

### R2-TD-02: Core gig and set messages use localization

The close-set label and typed gig/set errors use generated localization through `app_localizations` and `SongGroupErrorLocalizer`. Tests cover the localization mapping and controller error branches. Some secondary dialog copy is still hard-coded and needs a separate localization pass.

### R2-TD-03: Branch coverage is enforced by focused tests

Implemented. The repository now includes branch-focused tests across `song_groups`, `song_loader`, `lyrics_scroller`, and `preferences`, and `tool/check_coverage.dart` remains the enforcement script. Re-run the CI coverage job to refresh the percentage against the 80% target.

### R2-TD-04: Release 2 integration and keyboard workflows are covered

Implemented. `integration_test/release_2_workflow_test.dart` exercises gig creation, set/song ordering, persistence through repository reopening and widget rebuilding, and keyboard-only traversal on the desktop workflow. This does not by itself verify a full process restart or every native platform.

### R2-TD-05: Performance set mode protects gig-song selection

Resolved in the UI and controller. Opening a gig song locks the Songs library and panel tabs, including keyboard focus and swipe navigation. **Close set** restores panel access and clears the active set/song navigation state. The embedded song view shows the gig, set, and position with readable separators. Widget and controller tests cover these transitions; native accessibility-tree behavior still needs device-level verification.

## Verified or Deferred Requirements

- Core Release 2 features have no network client dependency and remain usable offline.
- Declarative routing is implemented with GoRouter and `MaterialApp.router`.
- Gig, set, and song-assignment models provide JSON serialization.
- Android library access uses the Storage Access Framework, including a persistable read grant; the native implementation enumerates and reads document URIs.
- The main layout adapts to available width and moves secondary panels into tabs on smaller screens.
- CI pins Flutter `3.47.1` on the stable channel.
- Linux and Web are identified as next platforms. Browser storage/file-handle support is therefore deferred from this Release 2 register.
- Screen-reader support is explicitly listed as a later-phase enhancement; this register does not treat it as a launch acceptance failure.
- A Windows Flutter accessibility-bridge `Failed to update ui::AXTree` log has been reported. Its runtime cause and resolution are not confirmed by widget tests; verify on a Windows build with the accessibility service before treating this as closed.
