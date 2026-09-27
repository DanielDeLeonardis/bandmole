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
}
