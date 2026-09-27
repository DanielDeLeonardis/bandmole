# Release 1 Cross-Cutting Technical Debt

> Status: implemented and closed for the current Release 1 codebase. This document remains as a historical record of the cross-cutting technical work that was completed to align the app with the Release 1 requirements and architecture, rather than as an open list of remaining issues.

This register reviews the Cross-Cutting Technical Requirements in [requirements.md](requirements.md) against the current Release 1 Songs Panel and lyrics-scroller implementation. It records gaps to implement or verify; it does not change runtime behavior. Priorities reflect Release 1 risk.

## Findings

### R1-TD-01: Android song-library access is not SAF-backed end to end

**Priority:** P1 — blocks reliable Android 10 library access and restoration

`MainView._pickDirectoryDialog` calls `FilePicker.getDirectoryPath` without Android SAF options. In the installed `file_picker` implementation, the default `AndroidOptions` does not carry `FilePickerAndroidOptions.safOptions`; the Android plugin consequently resolves a document-tree selection to a filesystem path and does not take a persistable URI grant. The app stores only that path. `SongLibrary.scanDirectory` then uses `Directory.listSync`, and `IoSongFileReader` uses `File.readAsBytes`. Those raw filesystem APIs do not consume a Storage Access Framework tree URI grant, so access to user-selected locations under Android scoped storage is not guaranteed, and the selected access cannot reliably be restored after restart.

**Fix direction:** Represent a selected Android library as a persisted SAF tree URI/handle, request a lifetime read grant, and make directory enumeration and song reads use `ContentResolver`/document-provider APIs. Keep the existing filesystem-path implementation for desktop platforms rather than treating a SAF URI as a `Directory` path.

**Acceptance:** On Android 10, choose a folder in shared storage, recursively list supported songs, open a song, force-stop and relaunch the app, and confirm the folder remains readable without asking for permission again. Also verify cancellation and revoked/missing grants surface a recoverable warning.

### R1-TD-02: Integration tests for native file browsing and persistence are missing

**Priority:** P1 — required cross-cutting test layer is absent

The repository has unit and widget tests, including an injected root-picker callback, but no `integration_test/` directory or integration driver. Thus native picker interaction, actual Android SAF access, and persistence across a real application restart are not exercised. Widget tests cannot prove those platform contracts.

**Fix direction:** Add integration coverage for Windows and Android Release 1 workflows: choose a root, browse folders, open a song, restart the app, and verify the root and access are restored. Keep platform picker interactions behind a seam so cancellation and unavailable-root cases remain testable.

**Acceptance:** CI or a documented device workflow runs integration tests for root selection, nested browsing, song loading, restart persistence, and cancellation on each required first-release platform.

### R1-TD-03: Branch coverage target is not measured or gated

**Priority:** P2 — required quality target cannot currently be assessed

`requirements.md` requires per-feature coverage measurement and at least 80% branch coverage. The repository documents `flutter test` and `dart analyze`, but has no coverage command/report, per-feature thresholds, or CI gate. The actual branch-coverage percentage is therefore unknown; this finding does not assert that it is below 80%.

**Fix direction:** Add a repeatable coverage workflow, separate or attribute coverage by feature area, and publish/check branch coverage against the 80% target. Exclude generated code only with an explicit documented policy.

**Acceptance:** A reproducible command produces branch-coverage results for each active feature area, and CI fails or reports clearly when an area is below 80%.

### R1-TD-04: Localization infrastructure is absent

**Priority:** P2 — architecture requirement is not established

User-facing strings in the active app are hard-coded in widgets and effects listeners. `pubspec.yaml` does not enable Flutter localization generation, and the project has no `l10n.yaml` or ARB resources. English is currently the only language, but there is no built-in localization boundary for future translations.

**Fix direction:** Set up Flutter's generated localization resources with English as the initial locale and migrate user-facing UI/error strings. Keep song text, lyrics, filenames, and ChordPro content outside localization transformations.

**Acceptance:** The app resolves all app-owned user-facing strings through generated localization resources, builds with English, and a test confirms song content is displayed unchanged.

### R1-TD-05: Keyboard-only Windows navigation has no acceptance test

**Priority:** P2 — Windows launch requirement is unverified

The UI uses standard Material controls, which provide baseline keyboard behavior, but the test suite contains no key-event or focus-traversal tests. The required Windows keyboard-only workflow through root selection, search, directory expansion, song selection, transport controls, and Preferences is therefore not demonstrated. Linux and Web keyboard checks belong to their later platform releases.

**Fix direction:** Add a Windows-oriented keyboard traversal test for the Release 1 workflows, verifying visible focus, predictable order, activation with Enter/Space, search editing, and access to the root chooser and Preferences. Add explicit focus handling only where the test exposes a gap.

**Acceptance:** A user can complete the listed Songs Panel and song-display workflows without a pointer, and automated tests cover those keyboard interactions.

### R1-TD-06: Flutter SDK version is not pinned despite the reproducibility claim

**Priority:** P2 — builds are not reproducible against a documented Flutter baseline

The README says the stable Flutter version is recorded, but the repository contains no Flutter version pin (such as `.fvmrc` or equivalent). `pubspec.yaml` constrains the Dart SDK to `^3.13.1`; that is a Dart range, not an exact Flutter SDK version, and it permits compatible upgrades.

**Fix direction:** Record the selected stable Flutter release in a repository-level toolchain pin and use the same version in local setup and CI. Update the README to reference the actual pin rather than an unspecified recorded version.

**Acceptance:** A clean environment can install the documented Flutter version and run dependency resolution, analysis, unit/widget tests, and platform builds with that version.

## Verified or Deferred Requirements

- Declarative navigation is implemented with `MaterialApp.router` and GoRouter.
- Core song browsing and lyrics display do not depend on network access.
- SharedPreferences is used for small user settings and panel state; the current Release 1 slice has no structured record store that requires SQLite. Reassess SQLite when structured song/group data is introduced.
- Windows has a native directory picker. Android uses the platform document-tree picker, but its grant/path integration remains the P1 issue above.
- Theme preferences and responsive side-by-side/tab layouts are present.
- JSON serialization is not currently needed by the active Release 1 state models.
- Linux and Web are specified as next platforms, and screen-reader support is explicitly later-phase; those are not recorded as Release 1 fixes here.
