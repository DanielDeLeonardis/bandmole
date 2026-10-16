# BandMole Agent Guide

Use this as a quick orientation; the linked documents are the source of truth for details. Keep changes aligned with the current implementation, and distinguish implemented behavior from product requirements.

## Project and stack

- Offline-first Flutter app for musicians. Releases 1 (Songs Panel/lyrics performance) and 2 (gigs and sets) are implemented; Releases 3–6 are planned. See [roadmap](docs/roadmap.md) and [requirements](docs/requirements.md).
- Flutter `3.47.1` is pinned in `.fvmrc`; Dart SDK constraint is `^3.13.1`. Use the pinned toolchain and `pubspec.yaml` for exact dependencies.
- Feature-first code lives in `lib/src/features/` (`song_loader`, `lyrics_scroller`, `song_groups`, `preferences`), with presentation/domain/data boundaries where applicable. See [architecture](docs/architecture.md).
- Riverpod manages state; Freezed models immutable data; GoRouter/`MaterialApp.router` provide declarative routes. The active performance song is embedded in `MainView`.
- `shared_preferences` stores small settings; native gigs/sets use SQLite (`sqflite`/`sqflite_common_ffi`) behind `GigRepository`, including legacy JSON migration. Song files stay in the user-selected library, not the database.

## Cross-cutting requirements

Summarized from [Cross-Cutting Technical Requirements](docs/requirements.md#cross-cutting-technical-requirements):

- Windows 10 and Android 10 are first-release targets; Linux and Web are next. Do not present planned platform support as implemented. Android library access uses a persisted Storage Access Framework grant.
- Keep core workflows offline. Network-backed features must not block them. SQLite is the primary native record store; Web needs browser-appropriate storage and file access when implemented.
- Preserve declarative routing, serialization where needed, generated localization (English initially), and responsive layouts based on available width rather than device labels. Never localize song content.
- Support keyboard-only navigation on desktop/Web target platforms; screen-reader support is a later-phase goal. Keep known Windows accessibility-bridge behavior in mind; see [Release 2 technical debt](docs/release_2_tech_debt.md).
- Add unit, widget, and integration tests for changed behavior. Measure coverage per feature and target at least 80% branch coverage; do not claim the threshold passes without a current report. Integration coverage should include library access, persistence, and core UI flows.

## Release 2 invariants

- Gig/set titles use case-insensitive, whitespace-normalized uniqueness; a song is assigned at most once per gig. Song assignments use paths relative to the selected library root. Missing files remain visible as editable broken links with manual relinking.
- Selecting a gig song enters set mode. While active, the Songs library and panel tabs (including keyboard focus and swipes) are locked; previous/next navigates the setlist. **Close set** unlocks the panels and clears active set/song navigation state. See [Release 2 requirements](docs/requirements.md#release-2-song-groups).
- Do not assume automatic filename-heuristic recovery, full-process restart coverage, or a resolved native accessibility-tree issue merely from the current tests; see [Release 2 technical debt](docs/release_2_tech_debt.md).

## Working and verification

- Prefer focused changes within the existing feature layers. For generated Freezed/Riverpod code, use `dart run build_runner build` when model/provider declarations change.
- Run targeted tests first, then `flutter test` and `dart analyze` when practical. CI also runs `flutter test --coverage --branch-coverage` and `dart run tool/check_coverage.dart`; the gate requires LCOV `BRDA` records. See [README testing](README.md#testing--static-analysis).
- Desktop integration workflows are `integration_test/release_1_workflow_test.dart` and `integration_test/release_2_workflow_test.dart` (for example, `flutter test integration_test/release_2_workflow_test.dart -d windows`). Do not substitute widget tests for native picker, restart, or accessibility verification.
- Follow the relevant [requirements](docs/requirements.md), [architecture](docs/architecture.md), and [changelog](CHANGELOG.md) when behavior changes; update documentation alongside code rather than inventing completed status.
