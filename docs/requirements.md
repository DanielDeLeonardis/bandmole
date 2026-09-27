# Requirements

## Product Overview

BandMole is an offline-first song management and performance app for solo musicians and bands, with the primary focus on an individual musician. Core features must remain available when network access is not available. Network-enabled features should degrade gracefully to offline-only behavior.

> Current implementation status: this repository already contains the initial Release 1 implementation for library browsing, persistent song-root selection, and lyric playback, while the later release sections describe future product work that is not yet implemented in the shipped app.

## Release Plan

Each major feature area is planned as a separate release for the first-release platforms. Every release includes both user-facing success criteria and implementation-level acceptance checks.

## Release 1: Songs Panel

### Goal

Provide a browsable, searchable song library that can be used to select songs for display and performance.

- The selected song directory is scanned after the user chooses it.
- Scanning includes subdirectories. Problems with files or paths are surfaced as warnings.
- The selected song directory is stored in user preferences.
- On Android and Web, directory permissions or handles are persisted across app restarts when supported by the platform.
- If the selected directory is unavailable, deleted, or on a disconnected drive, it is remembered and restored when it becomes available again. The user can change the root directory at any time.
- On smaller screens, the songs panel moves into a selectable tabbed layout.
- The panel should remember expanded folders and the last selected song across app restarts.
- Search does not inspect file contents.
- File extension matching is case-insensitive.
- When a song is renamed or moved, the app attempts to update references during refresh or when opening a gig using filename heuristics. If the match is ambiguous, the user can relink it manually. If it cannot do so, the reference is shown as broken.
- Selecting a file replaces the current song immediately; if unsaved changes exist in the editor, the app prompts the user to Save, Discard, or Cancel before switching.
- ChordPro files are shown as rendered text.
- If a song assigned to a gig is deleted from disk or the library, the gig reference remains and is shown as a broken link.

Technical acceptance:
- Given the app restarts, when the songs panel reloads, then expanded folders and the last selected song are restored.
- Given the selected directory is unavailable, when the library is scanned, then the directory remains remembered but is not shown as available until it can be restored.
- Given a file is selected, when the open action runs, then it replaces the current song state rather than opening a parallel view.
- Given the user cancels the navigation prompt when unsaved changes exist, then the current song and editor state remain untouched.

Failure cases and edge cases:
- Search does not match file contents.
- Multiple root song directories are out of scope.
- Showing unavailable directories as available is out of scope.

## Release 2: Song Groups

### Goal

Manage gigs and sets so a performer can plan, order, and navigate a performance setlist using songs selected from the Songs Panel.

### Gig

#### Requirements

- A gig groups together one or more sets for a performance.
- A gig stores:
  - title, entered by the user and required
  - date, optional
  - venue, optional
  - notes, optional
  - start time, optional
- A gig title is unique using case-insensitive comparison with normalized whitespace: leading and trailing whitespace is removed and runs of whitespace are collapsed.
- Set titles and custom directive names use the same case-insensitive comparison with normalized whitespace when uniqueness is required.
- Gigs are ordered alphabetically in the UI.
- The UI should provide an easy way to select a gig, such as a list, dropdown, or searchable picker.
- Deleting a gig must require confirmation.
- Deleting a gig leaves all song files untouched.

#### Success Criteria

User-facing:
- Given a user creates a gig with a unique title, when they save it, then the gig appears in the alphabetical gig list.
- Given a user opens the gig picker, when they browse available gigs, then they can select a gig without extra navigation friction.
- Given a user deletes a gig, when they confirm the action, then the gig is removed from the app.

Technical acceptance:
- Given two gigs with the same title, when the second save is attempted, then the app rejects the duplicate.
- Given a gig is saved, when the app is restarted, then its title and optional fields are restored.
- Given a gig delete action is triggered, when the user cancels the confirmation, then no data is removed.

Failure cases and edge cases:
- Duplicate gig titles are not allowed after case-insensitive whitespace normalization.
- Deleting a gig without confirmation is out of scope.
- Requiring a gig date is out of scope.

### Set

#### Requirements

- A set groups songs that will be performed together within a gig.
- Every gig contains at least one set, even when that set is empty.
- Set numbering must reflect its position in the gig, and renumber automatically when sets are reordered.
- A set title is entered by the user and must be unique within the gig.
- Set-title uniqueness uses case-insensitive comparison with normalized whitespace: leading and trailing whitespace is removed and runs of whitespace are collapsed.
- Songs must be unique across the whole gig, not just within one set.
- Song assignments store the relative path of the song within the root song directory.
- Songs can be added from the Songs Panel by selection or by drag-and-drop, and only once per gig.
- Songs can be deleted from a set.
- Songs can be reordered within a set using up/down controls and drag-and-drop.
- If a song is missing from disk, the gig remains usable and the song is shown as a broken link rather than automatically entering recovery mode.
- A broken song link must be indicated in red with a tooltip explaining the problem.
- The user can remove the missing song or re-link it to any supported song file.
- Navigating past the end of one set continues automatically into the next set, and navigating backward from the start of one set continues into the previous set.

#### Success Criteria

User-facing:
- Given a gig with multiple sets, when the user reorders the sets within that gig, then the visible set numbers update immediately.
- Given a song is already used somewhere in a gig, when the user tries to add it again, then the app prevents the duplicate.
- Given a user renames a set, when the new title is unique within the gig, then the change is saved successfully.
- Given a user adds a song from the Songs Panel by selection or by drag-and-drop, when they add it to a set, then the song appears in the set.
- Given the user moves through songs in order, when they advance past the end of a set, then the app continues to the next set automatically.
- Given a song file is missing, when the gig is opened, then the broken link is clearly visible in red with a tooltip, and the user can remove or re-link the song without the gig becoming read-only.

Technical acceptance:
- Given a gig is loaded and one of its songs is missing from disk, when load validation runs, then the song is marked as a broken link while the gig remains editable.
- Given a missing song is re-linked or removed, when changes are saved, then the broken link is cleared.
- Given a set is reordered, when the data model is saved, then the stored set order and visible numbering match.
- Given a song is assigned to a gig, when a second assignment is attempted anywhere else in that gig, then the validator rejects it.
- Given a set title duplicates another set title in the same gig, when the user tries to save it, then the app rejects the duplicate.

Failure cases and edge cases:
- Duplicate songs across the gig are not allowed.
- Duplicate set titles within the same gig are not allowed.
- Renaming a set to a title that already exists in the same gig is rejected.
- Missing songs produce broken links but do not prevent normal gig editing.
- Wrap-around navigation is limited to moving from the end of one set to the next set; wrapping from the final set is not defined here.

## Release 3: ChordPro Editor

### Goal

Create, edit, preview, and save songs in ChordPro format with minimal manual cleanup.

### Requirements

- The editor supports both creating new songs and editing existing ChordPro songs.
- The editor supports drag-and-drop workflows for:
  - dragging chords onto lyrics
  - dragging sections around
  - dragging directives from a list
- Release 3 must support these ChordPro directives: `album`, `arranger`, `artist`, `capo`, `chord`, `chordfont`, `chordsize`, `chordcolour`, `chorus`, `composer`, `diagrams`, `duration`, `key`, `lyricist`, `start_of_bridge`, `start_of_chorus`, `start_of_verse`, `subtitle`, `tempo`, `time`, `title`, `titlefont`, `titlesize`, `titlecolour`, `transpose`, and `year`.
- The editor should target ChordPro format 6.101.
- ChordPro syntax for supported directives, repeated directives, comments, unknown directives, and line endings follows the ChordPro 6.101 specification.
- Custom directives can be defined globally and per song.
- Custom directives should be available alongside built-in directives and embedded in the song file when used.
- The first supported custom directive is `scroll_speed`; when it is absent, the default scroll speed is `5`.
- The preview panel renders formatted lyrics and chords.
- The outline panel shows verses, choruses, bridges, directives, and any other structural sections recognized by the editor.
- Conversion from plain text to ChordPro happens only when the user explicitly chooses it.
- The converter must support plain lyric sheets and chord sheets with chords inline, on a separate line, or above lyrics.
- Converted files use the `.chopro` extension. The original plain-text source remains unchanged alongside the converted file for the user to manage.
- Conversion should prioritize correctness and minimal cleanup.
- If the converter is unsure about a section label, chord placement, or formatting, it should leave the ambiguity for the user to fix.
- Suggestions and hints must be dismissible and their dismissed state should persist between sessions.
- The editor preserves comments, unknown directives, whitespace, and line endings when saving.
- Navigating away from the editor or switching songs with unsaved changes must prompt the user to Save, Discard, or Cancel.

### Success Criteria

User-facing:
- Given a user opens a new or existing song, when they edit it, then they can save it as ChordPro.
- Given a user drags a chord, section, or directive, when they drop it into the editor, then the song updates without requiring manual code editing for the common path. Dragging a chord creates a new chord annotation.
- Given a user opens the preview panel, when the song contains ChordPro markup, then the formatted lyrics and chords render correctly.
- Given a user converts a plain text or chord sheet, when the conversion is ambiguous, then the user can review and correct the result.
- Given the user has unsaved edits in the editor, when they navigate away or switch songs, then they are prompted with Save, Discard, and Cancel options.

Technical acceptance:
- Given a song uses a custom directive, when the song is saved, then that directive is persisted with the song content.
- Given the editor loads an existing ChordPro file, when the document is rendered, then it remains compatible with ChordPro 6.101 expectations.
- Given the converter cannot classify a section or chord placement confidently, when conversion completes, then it preserves ambiguity instead of inventing incorrect structure.
- Given a converted song is saved, when the original source is needed, then it remains available as the untouched separate source file.
- Given the user cancels navigation from the unsaved changes prompt, then the editor retains its current buffer and focus.

Failure cases and edge cases:
- Automatic conversion is not allowed without explicit user action.
- Perfect conversion is not guaranteed for ambiguous source text.
- Dismissed hints should stay dismissed across sessions.
- Unsaved changes must never be discarded without explicit user consent.

## Release 4: Song Charts

### Goal

Help users find chord layouts for supported instruments and save useful results.

### Requirements

- The chart panel can search for the layout of a chord.
- Search should cover all of the following:
  - chord diagrams
  - voicings
  - fingerings
- Chord searches support chord names including sharps, flats, slash chords, altered chords, and extensions.
- The launch instruments are guitar, bass guitar, and ukulele.
- The panel should support both a built-in chart library and dynamically generated charts.
- Users can save favorite chord charts by instrument and chord name.
- Generated chart results are ranked using a combination of musical preference, common voicing, difficulty, and fret movement, and show confidence or difficulty information.

### Success Criteria

User-facing:
- Given a user searches for a chord, when charts are available, then the app returns matching layouts for the supported instruments.
- Given a user finds a useful chart, when they save it as a favorite, then it is available for later use.
- Given a chord is not in the built-in library, when the user searches, then the app can still generate a usable chart if possible.

Technical acceptance:
- Given a supported instrument and chord, when a chart search is performed, then the implementation can return both built-in and generated results, ranked by the combined preference criteria.
- Given a favorite chart is saved, when the app restarts, then the favorite persists.

Failure cases and edge cases:
- Unsupported instruments are out of scope for launch.
- Searching only diagrams, only voicings, or only fingerings is supported as part of the same unified search.

## Release 5: Metadata

### Goal

Use MusicBrainz to help populate ChordPro metadata fields with a review step before writing changes.

### Requirements

- MusicBrainz matching should target song, artist, and release.
- Metadata imports should include:
  - artist
  - album
  - composer
  - title
  - year
  - lyricist
  - duration
- Metadata can be fetched from filename matching, manual search, or both.
- Filename matching and automatic lookup behavior are user preferences.
- Metadata lookup results are cached and requests are rate-limited.
- When multiple MusicBrainz releases match, the user can select a release or configure a preference for automatic selection.
- By default, metadata fills missing fields only.
- The user must be given the option to overwrite existing fields after review.
- There must be a review step before metadata is written into the file.
- MusicBrainz attribution is displayed when imported metadata is presented or applied.
- If no confident MusicBrainz match is found, the review screen allows manual editing; this behavior can be configured as a user preference.
- Multiple composers and lyricists are represented using repeated directives.

### Success Criteria

User-facing:
- Given a song with missing metadata, when the user searches manually or via filename matching, then the app can propose values for review.
- Given the review screen shows imported metadata, when the user accepts it, then the chosen fields are written to the song.
- Given existing fields are already populated, when metadata is imported, then the default behavior preserves those values unless the user chooses overwrite.

Technical acceptance:
- Given a lookup completes, when values are written, then only the selected fields are updated by default, including multiple values represented by repeated directives.
- Given the user rejects the review, when the process ends, then the file remains unchanged.
- Given offline mode is active, when metadata lookup is unavailable, then the core app remains usable without blocking other features.

Failure cases and edge cases:
- Metadata writing without user review is out of scope.
- Overwriting existing values requires an explicit user choice.

## Release 6: Data Import and Export

### Goal

Enable musicians to back up, restore, and migrate their application data—either in full or by selecting specific objects—with safety warnings, per-item and bulk skip/overwrite choices when conflicts arise, and portable ZIP archive bundling.

### Requirements

#### Export
- The user can export all application data or select specific objects/categories to export.
- Export selection supports both whole categories and individual objects.
- Selectable export objects include:
  - Gigs and sets (song groups)
  - Favorite chord charts
  - Custom directives (global)
  - User preferences and app settings
  - Song files and metadata
- Export generates a standard `.zip` archive containing:
  - Structured JSON data files for database records (gigs, sets, favorites, directives, preferences)
  - Manifest file defining the schema version, exported entity types, and creation timestamp
  - Exported song files stored with relative paths within the archive
- Exported song paths are always relative paths.
- The user can select the export destination file path using the platform file picker.

#### Import & Conflict Handling
- The user can import a complete archive or selectively choose specific objects from the archive.
- Import selection supports both whole categories and individual objects.
- The app validates the ZIP archive structure, manifest version, and JSON schema integrity before presenting import options.
- The initial conflict keys are normalized gig titles, normalized custom directive names, settings keys, and relative song paths. These keys may be refined as the feature data models are implemented.
- Before applying changes, the app identifies any objects that would overwrite existing data (e.g. duplicate gig titles, existing custom directives, conflicting settings, or song files with different content).
- When a conflict is detected, the user is warned and given explicit conflict resolution choices:
  - Proceed (overwrite the existing item with the imported version)
  - Skip (keep the existing item and discard the imported version)
  - Bulk actions: "Overwrite All" or "Skip All" to apply the decision across all remaining conflicts
- Non-conflicting objects are imported without unnecessary friction.
- Imported song files are matched to existing local songs by relative path where possible. Files with the same path and content are skipped without prompting. Files with the same path but different content require the same per-item or bulk overwrite/skip choice as other conflicts.
- Imported song files that do not already exist are extracted into the currently configured root song directory, preserving their relative subfolder paths.
- The user is presented with a summary of imported, overwritten, and skipped objects upon completion.
- Failed imports or schema validation errors must fail gracefully without leaving partial or corrupted state.
- Import uses temporary staging so that database changes and extracted song files can be rolled back together if the operation fails or is cancelled.
- Import validates that archive song paths are relative and contained within the configured song directory before extraction.

### Success Criteria

User-facing:
- Given an existing collection of gigs, favorites, and settings, when the user chooses full export, then a single `.zip` archive containing the JSON manifest and song files is created.
- Given an export file, when the user selects specific objects to import, then only the chosen items are imported.
- Given an imported object has the same normalized conflict key as an existing object (e.g. a normalized gig title), when the import is processed, then the user is prompted with an overwrite warning and can choose Proceed, Skip, or a bulk resolution ("Overwrite All" / "Skip All").
- Given an imported song has the same relative path as a local song, when both files have identical content, then the local file is retained without a conflict prompt.
- Given an imported song has the same relative path as a local song with different content, when the import is processed, then the user can overwrite or skip that file individually or in bulk.
- Given a user chooses to skip a conflicting object, when the import finishes, then the local object remains unchanged.
- Given a user chooses to proceed on a conflicting object, when the import finishes, then the local object is updated with the imported data.
- Given a user selects "Skip All" or "Overwrite All", then that decision is applied to all subsequent conflicting objects without repeated individual prompts.

Technical acceptance:
- Given an invalid or corrupted ZIP archive or JSON payload, when the user initiates an import, then the parser rejects the file with an informative error message and makes no database changes.
- Given an import operation with a mix of new and conflicting items, when the user skips conflicts, then new items are persisted and skipped items are untouched.
- Given an import is interrupted or cancelled, when the operation aborts, then database transaction rollback prevents partial or orphan data.

Failure cases and edge cases:
- Overwriting existing objects without an explicit user prompt or bulk consent is strictly prohibited.
- Importing corrupted or unsupported archive versions must abort with rollback.
- Importing songs with broken or missing file paths in an archive must surface clear warnings without corrupting gig structures.
- Where possible, newer archive schema versions should be migrated during import; versions that cannot be migrated must be rejected with rollback.

## Cross-Cutting Technical Requirements

### Platforms

- Windows 10 and Android 10 are required first-release platforms.
- Linux and Web are next.
- Other platforms, including iOS and macOS, are aspirational.
- Android behavior should follow the platform's expected file-access and picker conventions; where desktop file access does not apply, an appropriate Android-specific workflow must be provided.

### Storage and Offline Behavior

- Core features must work offline.
- Network-dependent features must not block offline features when the network is unavailable.
- SQLite is the primary persistence layer for supported native platforms.
- A platform-specific storage fallback is acceptable where SQLite is not the best option.
- For web, storage should be browser-based, such as IndexedDB or OPFS, with import/export flows for local song libraries.
- For web, local file access should use browser-supported mechanisms such as file picker import and, where available, the File System Access API.

### Architecture and App Quality

- The app should follow Flutter and Dart architecture best practices.
- Declarative routing should be used.
- JSON serialization should be supported where needed.
- Localization should be built in.
- The app should support keyboard-only navigation at launch on Windows, Linux, and Web. Android hardware-keyboard navigation is not required at launch.
- Screen reader support is a later-phase accessibility enhancement.
- Application polish includes:
  - animations
  - theming
  - accessibility
  - keyboard shortcuts
  - startup performance
  - English is the initial localization language, and song content must remain untouched by localization.
  - The project should use the latest stable Flutter release available when development begins and record that version for reproducible builds.

### Responsive Design

- The UI must adapt to available screen size rather than fixed device classes.
- Smaller widths should move secondary panels, such as the songs panel, into alternate selectable layouts such as tabs.

### Testing

- Unit, widget, and integration tests are required.
- Coverage should be measured per feature area.
- Each feature area should target at least 80% branch coverage.
- Integration tests should cover file browsing and persistence in addition to core UI flows.

## Notes

- The app should prioritize correctness over speculative automation.
- When the app cannot confidently infer structure or metadata, it should leave the decision to the user.
