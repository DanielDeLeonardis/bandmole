import 'generated/app_localizations.dart';

class EnglishAppLocalizations extends AppLocalizations {
  EnglishAppLocalizations() : super('en');

  @override
  String get appTitle => 'BandMole';
  @override
  String get preferences => 'Preferences';
  @override
  String get chooseSongLibraryFolder => 'Choose song library folder';
  @override
  String get selectSongLibraryFolder => 'Select song library folder';
  @override
  String get searchSongsAndFolders => 'Search songs and folders';
  @override
  String get clearSearch => 'Clear search';
  @override
  String get caseSensitiveSearchOn => 'Case-sensitive search on';
  @override
  String get caseSensitiveSearchOff => 'Case-sensitive search off';
  @override
  String get selectSongToView => 'Select a song to view it here.';
  @override
  String get noMatchingSongsOrFolders => 'No matching songs or folders.';
  @override
  String get noSongsFound => 'No songs found.';
  @override
  String get noLibrarySelected => 'No library selected';
  @override
  String rootLabel(String path) => 'Root: $path';
  @override
  String get songsTab => 'Songs';
  @override
  String get songTab => 'Song';
  @override
  String get songSelectionUnsupported =>
      'Song selection is not supported on this platform.';
  @override
  String get unableToLoadSong => 'Unable to load song.';
  @override
  String get noSongSelected => 'No song selected.';
  @override
  String get encodingIssues =>
      'Song contents has encoding issues. Please review.';
  @override
  String get libraryUnavailable =>
      'The song library is unavailable. Choose it again.';
  @override
  String get decreaseTextFontSize => 'Decrease text font size';
  @override
  String get increaseTextFontSize => 'Increase text font size';
  @override
  String get transposeDown => 'Transpose down one semitone';
  @override
  String get resetTransposition => 'Reset transposition';
  @override
  String get transposeUp => 'Transpose up one semitone';
  @override
  String get goToStart => 'Go to start';
  @override
  String get stopScrolling => 'Stop scrolling';
  @override
  String get startScrolling => 'Start scrolling';
  @override
  String get goToEnd => 'Go to end';
  @override
  String get decreaseScrollSpeed => 'Decrease scroll speed';
  @override
  String get increaseScrollSpeed => 'Increase scroll speed';
  @override
  String get textFontSize => 'Text font size';
  @override
  String get transposeSemitones => 'Transpose semitones';
  @override
  String get scrollSpeed => 'Scroll speed';
  @override
  String get gigsTab => 'Gigs';
  @override
  String get gigs => 'Gigs';
  @override
  String get selectGig => 'Select Gig';
  @override
  String get createGig => 'Create Gig';
  @override
  String get editGig => 'Edit Gig';
  @override
  String get deleteGig => 'Delete Gig';
  @override
  String get deleteGigConfirmation =>
      'Are you sure you want to delete this gig? Song files will remain untouched.';
  @override
  String get gigTitle => 'Gig Title';
  @override
  String get gigTitleRequired => 'Gig title is required';
  @override
  String get gigDate => 'Date';
  @override
  String get gigVenue => 'Venue';
  @override
  String get gigNotes => 'Notes';
  @override
  String get gigStartTime => 'Start Time';
  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get sets => 'Sets';
  @override
  String get addSet => 'Add Set';
  @override
  String get renameSet => 'Rename Set';
  @override
  String get deleteSet => 'Delete Set';
  @override
  String get setTitle => 'Set Title';
  @override
  String get setTitleRequired => 'Set title is required';
  @override
  String setNumber(int number) => 'Set $number';
  @override
  String get noGigsFound => 'No gigs found. Create one to get started.';
  @override
  String get noSetsInGig => 'No sets in this gig.';
  @override
  String get emptySetDropSongsHere =>
      'Empty set. Drop songs here or select from Songs panel.';
  @override
  String get addToSet => 'Add to Set';
  @override
  String get addToCurrentSet => 'Add to current set';
  @override
  String get relinkSong => 'Re-link Song';
  @override
  String get removeSong => 'Remove Song';
  @override
  String get moveSongUp => 'Move song up';
  @override
  String get moveSongDown => 'Move song down';
  @override
  String get moveSetUp => 'Move set up';
  @override
  String get moveSetDown => 'Move set down';
  @override
  String brokenSongTooltip(String path) => 'Song file missing from disk: $path';
  @override
  String get duplicateGigTitle => 'A gig with this title already exists.';
  @override
  String get duplicateSetTitle =>
      'A set with this title already exists in this gig.';
  @override
  String get duplicateSongInGig => 'This song is already in this gig.';
  @override
  String get gigMustHaveAtLeastOneSet => 'A gig must contain at least one set.';
  @override
  String get nextSong => 'Next song';
  @override
  String get previousSong => 'Previous song';
  @override
  String get closeSet => 'Close set';
  @override
  String get unsupportedSongFile => 'The song file type is not supported.';
  @override
  String get setNotFound => 'Set not found in this gig.';
  @override
  String get editorTitle => 'ChordPro Editor';
  @override
  String get editorNewSong => 'New ChordPro song';
  @override
  String get editorEditSong => 'Edit ChordPro song';
  @override
  String get editorConvertSong => 'Convert text song to ChordPro';
  @override
  String get editorClose => 'Close editor';
  @override
  String get editorSource => 'ChordPro source';
  @override
  String get editorPreview => 'Preview';
  @override
  String get editorOutline => 'Outline';
  @override
  String get editorFilename => 'Song filename';
  @override
  String get editorConvert => 'Convert to ChordPro';
  @override
  String get editorHint =>
      'Place the cursor, then tap or drag a chord or directive into the editor.';
  @override
  String get editorDismiss => 'Dismiss';
  @override
  String get editorCustomDirective => 'Custom directive';
  @override
  String get editorCustomName => 'Name';
  @override
  String get editorAdd => 'Add';
  @override
  String get editorInvalidCustomName => 'Use a new lowercase directive name.';
  @override
  String get editorConvertBeforeSave =>
      'Choose Convert before saving a text song.';
  @override
  String get editorSongSaved => 'Song saved.';
  @override
  String get editorUnsavedChanges => 'Unsaved changes';
  @override
  String get editorSaveBeforeLeaving =>
      'Save changes before leaving the editor?';
  @override
  String get editorDiscard => 'Discard';
  @override
  String editorSaveFailed(String error) => 'Unable to save song: $error';
  @override
  String editorLine(int number) => 'Line $number';
}
