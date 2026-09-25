# Product Requirements Document

## 1. Product Summary

BandMole is an offline-first song management and performance application for solo musicians and bands, with the primary emphasis on the individual musician workflow. The product must remain useful without network access and should degrade gracefully when network-backed features are unavailable.

## 2. Product Goals

- Help musicians organize songs into gigs and sets.
- Provide a searchable local song library.
- Support ChordPro creation, editing, previewing, and conversion.
- Add chord chart lookup and metadata enrichment.
- Preserve a fast, keyboard-friendly, responsive workflow across supported platforms.

## 3. Non-Goals

- Multiple root song libraries at launch.
- Full screen-reader accessibility at launch.
- Automatic metadata overwriting without review.
- Unsupported instrument chart coverage at launch.
- Speculative AI conversion that guesses beyond the source material.

## 4. Target Users

- Solo musicians managing a personal song library.
- Bands needing gig and set planning.
- Musicians who want to author or clean up ChordPro songs.

## 5. Release Priorities

Each feature area is delivered as a separate release for the first-release platforms.

### Priority 0

- Offline app shell and persistent storage.
- Songs Panel.
- Song Groups.

### Priority 1

- ChordPro Editor.
- Song Charts.

### Priority 2

- Metadata integration.
- Data import and export.
- Additional platform expansion.

## 6. Feature Requirements

### 6.1 Songs Panel

Requirements:
- One song root directory selected through a directory-only picker.
- If no directory has been chosen yet, the app prompts the user to select one before scanning it.
- The selected directory is stored in user preferences.
- Scanning includes subdirectories, and file or path problems are surfaced as warnings.
- Android and Web directory permissions or handles are persisted across restarts where supported by the platform.
- Only one root song directory is supported.
- Unavailable, deleted, or disconnected directories are remembered and restored when available again; the user can change the root directory.
- Changes outside the app are detected on refresh and when opening a gig.
- Supported file extensions are the configured text and ChordPro extensions (`.cho`, `.crd`, `.chopro`, `.chordpro`, `.pro`, and `.txt`).
- File extension matching is case-insensitive.
- Songs are referenced by relative paths from the root song directory to ensure portability.
- Song references are updated using filename heuristics when renamed or moved; ambiguous matches can be manually relinked, and unresolved references are shown as broken links.
- On smaller screens, the songs panel moves into a selectable tabbed layout.
- The layout adapts to available screen size rather than fixed breakpoints.
- Search is limited to file and folder names.
- Remember expanded folders and the last selected song.
- Selecting a file replaces the current song immediately; if unsaved changes exist in the editor, prompt user to Save, Discard, or Cancel before switching.
- Song deletion is a separate confirmed user operation and leaves files untouched until explicitly confirmed.
- If a song assigned to a gig is deleted, the existing gig reference remains as a broken link.

Acceptance:
- The UI restores the selected directory, expanded folders, and the last selected song.
- The UI remembers unavailable directories and restores them when available.
- The songs panel moves into a selectable tabbed layout on smaller screens.
- Text files render as raw text, and ChordPro files render formatted lyrics and chords.
- Switching songs with unsaved changes displays a confirmation dialog.

### 6.2 Song Groups

Requirements:
- Create and manage gigs and sets.
- Store a user-entered gig title, optional date, venue, notes, and start time.
- Store start time as a local wall-clock time.
- Enforce unique gig titles using case-insensitive comparison with trimmed and collapsed whitespace.
- Add songs to sets from the Songs Panel by selection or by drag-and-drop, once per gig.
- Add, remove, reorder, and navigate sets and songs.
- Every gig contains at least one set, even if it is empty.
- Set titles are entered by the user and must be unique within a gig.
- Set titles and custom directive names use case-insensitive comparison with trimmed and collapsed whitespace when uniqueness is required.
- Songs are stored using relative paths within the root song directory.
- Prevent duplicate songs across a gig.
- If a song is missing from disk, the gig remains editable and shows a broken link highlighted in red with an explanatory tooltip.
- Users can re-link a broken song to any supported song file or remove it.

Acceptance:
- Gigs and sets persist across restarts.
- Set numbers renumber when the order changes.
- Set titles can be renamed as long as they remain unique within the gig.
- Navigation continues from one set to the next set automatically, and backward from the start of one set into the previous set.
- Gigs with missing songs remain editable while broken links are shown.

Failure cases:
- Duplicate songs across a gig are rejected.
- Renaming a set to a title that already exists elsewhere in the same gig is rejected.

### 6.3 ChordPro Editor

Requirements:
- Create and edit songs.
- Drag-and-drop support for lyrics, sections, and directives; dragging a chord creates a new chord annotation.
- Support the defined Release 3 directive set for ChordPro 6.101: `album`, `arranger`, `artist`, `capo`, `chord`, `chordfont`, `chordsize`, `chordcolour`, `chorus`, `composer`, `diagrams`, `duration`, `key`, `lyricist`, `start_of_bridge`, `start_of_chorus`, `start_of_verse`, `subtitle`, `tempo`, `time`, `title`, `titlefont`, `titlesize`, `titlecolour`, `transpose`, and `year`.
- Follow the ChordPro 6.101 specification for supported syntax, repeated directives, comments, unknown directives, whitespace, and line endings.
- Custom directives at both global and per-song scope are embedded in the song file when used.
- The first supported custom directive is `scroll_speed`, with a default value of `5` when absent.
- Explicit conversion from text to ChordPro.
- Convert plain lyric sheets and chord sheets with inline, separate-line, or above-lyric chords to `.chopro` while leaving the original source untouched alongside it.
- Preserve comments, unknown directives, whitespace, and line endings when saving.

Acceptance:
- Preview and outline panels reflect the current song structure.
- Conversion remains conservative when uncertain.
- Dismissed hints remain dismissed between sessions.

### 6.4 Song Charts

Requirements:
- Search chord diagrams, voicings, and fingerings.
- Support guitar, bass guitar, and ukulele.
- Support chord names including sharps, flats, slash chords, altered chords, and extensions.
- Provide built-in and generated chart results.
- Allow favorite charts to be saved by instrument and chord name.
- Rank generated charts using a combination of musical preference, common voicing, difficulty, and fret movement, with confidence or difficulty information shown.

Acceptance:
- Chart search returns usable results for supported instruments.
- Favorites persist across restarts.

### 6.5 Metadata

Requirements:
- Import artist, album, composer, title, year, lyricist, and duration.
- Match MusicBrainz song, artist, and release data; cache lookup results, rate-limit requests, and display MusicBrainz attribution.
- Support filename matching and manual search.
- Make filename matching, automatic lookup, release selection, and no-match handling configurable preferences.
- Fill missing fields first.
- Require review before writing to file.
- Allow user-approved overwrite of existing data.
- Allow manual editing in the review screen when no confident match is found.
- Represent multiple composers and lyricists using repeated directives.

Acceptance:
- Metadata review is a separate step before write-back.
- Offline mode does not block core song workflows.

### 6.6 Data Import and Export

Requirements:
- Export all application data or selectively choose specific objects (gigs, sets, song files, favorites, custom directives, preferences).
- Support selecting whole categories or individual objects for export and import.
- Package exports into a standard `.zip` archive containing structured JSON data files, a versioned manifest, and song files.
- Exported song paths are relative paths.
- Validate archive integrity, manifest version, and JSON schemas prior to import.
- Detect overwrite conflicts (such as duplicate gig titles or existing directives) and prompt with Proceed, Skip, or bulk actions ("Overwrite All", "Skip All").
- Use normalized gig/directive names, settings keys, and relative song paths as initial conflict keys.
- Reuse local songs by relative path when content matches; prompt only when the content differs.
- Support future archive schema migration where possible and reject unmigratable versions with rollback.
- Ensure atomic transactions with rollback on import failure to prevent data corruption.
- Stage database and song-file changes together, validate archive paths are relative and contained within the configured song directory, and roll back both database changes and extracted files if import fails or is cancelled.

Acceptance:
- Full and granular exports create valid, portable `.zip` bundles.
- Conflicting objects are never overwritten without explicit user authorization or bulk confirmation.
- Skipped items leave existing data untouched.

## 7. Technical Constraints

- Windows 10 and Android 10 are required first-release platforms.
- Linux and Web are secondary targets.
- iOS and macOS are aspirational.
- Android file access and picker behavior should follow platform conventions; where desktop file access does not apply, an appropriate Android workflow must be provided.
- Offline-first behavior is mandatory.
- SQLite is the primary persistence layer on supported native platforms.
- A platform-specific storage fallback is acceptable where needed.
- Web storage should use browser-native persistence such as IndexedDB or OPFS.
- Local file access on web should use browser-supported import flows.
- Declarative routing is required.
- JSON serialization and localization are required.
- Keyboard-only navigation is required at launch on Windows, Linux, and Web, but not for Android hardware keyboards.
- Screen-reader support is deferred.
- The UI must be responsive to screen size rather than device class.
- English is the initial localization language, and song content remains untouched by localization.
- The Flutter version used at project start must be recorded for reproducible builds.
- Each feature area targets at least 80% branch coverage, with integration tests for file browsing and persistence.

## 8. Success Metrics

- Users can open the app and reach their local library offline.
- Users can build and navigate gigs without data-loss or duplicate-song errors.
- Users can edit and preview ChordPro files with minimal manual cleanup.
- Users can search chord charts and save favorites.
- Users can review metadata before any file changes are written.

## 9. Risks and Dependencies

- File access differs significantly between desktop, mobile, and web.
- Conversion quality depends on source text consistency.
- Metadata services depend on external availability and network conditions.
- The responsive layout must handle a wide range of screen sizes without creating separate app variants.

## 10. Milestones

### Milestone 1

- Offline app shell
- Local storage
- Songs Panel
- Song Groups

### Milestone 2

- ChordPro Editor
- Preview and outline rendering
- Conversion workflow

### Milestone 3

- Song Charts
- Favorite charts

### Milestone 4

- Metadata lookup
- Review and write-back

### Milestone 5

- Data import and export
- Backup packaging and conflict handling

## 11. Open Questions

- Exact layout breakpoints are intentionally left adaptive rather than fixed.
- The precise implementation for web file access should follow the best available browser-supported approach.
- Screen-reader support will be defined in a later accessibility pass.
