# BandMole Roadmap

## Purpose

This roadmap turns the full requirements into a release sequence that is easier to scan at a glance. It keeps the same feature ordering as the requirements document, but trims the detail down to release goals, dependencies, and completion signals.

Each feature area is delivered as a separate release for the first-release platforms.

## Release Sequence

### Release 1: Songs Panel

Goal:
- Provide a browsable song library with search, persistent folder state, and a responsive panel layout.

Depends on:
- File system access
- Persistent user preferences

Success signal:
- The app prompts for a folder with a directory-only picker, remembers unavailable roots, and restores them when available again.
- The library scans subdirectories, surfaces file and path warnings, and persists Android or Web directory permissions or handles where supported.
- It restores expanded folders and the last selected song, and replaces the current song immediately when a file is selected.
- Refresh and gig opening detect external changes and use filename heuristics to follow renamed or moved songs, with manual relinking for ambiguous matches and broken links when unresolved.
- The songs panel moves into a selectable tabbed layout on smaller screens.

### Release 2: Song Groups

Goal:
- Let a musician build, reorder, and navigate gigs and sets using songs selected from the Songs Panel.

Depends on:
- Song storage and persistence
- Song selection from the Songs Panel

Success signal:
- A gig can be created, saved, reopened, and used to move through songs and sets in order.
- Gig titles can be entered as user input and remain unique after case-insensitive whitespace normalization.
- Songs can be added to sets from the Songs Panel by selection or by drag-and-drop.
- Set titles can be entered and renamed as long as they remain unique within the gig.
- Set titles use case-insensitive comparison with normalized whitespace, and deleted songs remain as broken links in existing gigs.
- Missing songs remain editable as clearly marked broken links and can be removed or re-linked.

### Release 3: ChordPro Editor

Goal:
- Create and edit ChordPro songs with preview, outline, and conversion support.

Depends on:
- Song file persistence
- Lyrics rendering
- Directive parsing and formatting

Success signal:
- Users can author or convert songs with minimal cleanup and save valid ChordPro output.

### Release 4: Song Charts

Goal:
- Help users find, generate, and save chord charts for supported instruments.

Depends on:
- Chord chart data and chart-generation logic

Success signal:
- Users can search chord layouts, view results for supported instruments, and save favorites.

### Release 5: Metadata

Goal:
- Import and review MusicBrainz metadata before writing changes.

Depends on:
- External metadata lookup
- Review and write-back workflow

Success signal:
- Users can search for metadata, review proposed changes, and choose whether to write them.
- Lookup results are cached, requests are rate-limited, and MusicBrainz attribution is displayed.

### Release 6: Data Import and Export

Goal:
- Provide full and granular export/import of library data, songs, and preferences packaged in ZIP archives, with conflict warnings and skip/overwrite options.

Depends on:
- Song file persistence
- Gig and set persistence
- Archive packaging (ZIP) and JSON serialization

Success signal:
- Users can export or import the entire library or specific objects.
- Overwrite warnings are displayed when conflicts are detected, with options to proceed, skip, or apply bulk actions.
- Imports validate relative paths, stage database and file changes together, and roll back both when an import fails or is cancelled.

## Cross-Cutting Milestones

### Milestone A: Offline Foundation

- Offline-only workflows remain usable when the network is unavailable.
- Native persistence is in place.
- Basic responsive layout works across desktop and mobile sizes.

### Milestone B: Library and Setlist Workflow

- Songs can be selected from a single root directory.
- Songs can be dragged or selected into gigs and sets.
- Gigs and sets can be created and navigated.
- Set title renames are validated so duplicate titles in the same gig are rejected.
- Broken links are surfaced clearly.

### Milestone C: Editing Workflow

- ChordPro editing and preview are available.
- The defined ChordPro 6.101 directives and conservative conversion workflows are supported.

### Milestone D: Discovery and Enrichment

- Chord chart search and metadata lookup are available.
- Review steps are used before writing metadata.

### Milestone E: Backup and Migration

- Full and granular import and export workflows are available.
- Overwrite protection, conflict warnings, and ZIP packaging are supported.

### Milestone F: Verification

- Each feature area targets at least 80% branch coverage.
- Integration tests cover file browsing and persistence in addition to core UI flows.

## Priority Summary

P0:
- Offline-first app shell
- Songs Panel
- Song Groups

P1:
- ChordPro Editor
- Song Charts

P2:
- Metadata enrichment
- Data import and export
- Broader platform expansion

## Notes

- Windows 10 and Android 10 are first-release platforms.
- Linux and Web come next.
- iOS and macOS remain aspirational until the core workflow is stable.
