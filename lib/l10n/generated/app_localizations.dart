import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BandMole'**
  String get appTitle;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @chooseSongLibraryFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose song library folder'**
  String get chooseSongLibraryFolder;

  /// No description provided for @selectSongLibraryFolder.
  ///
  /// In en, this message translates to:
  /// **'Select song library folder'**
  String get selectSongLibraryFolder;

  /// No description provided for @searchSongsAndFolders.
  ///
  /// In en, this message translates to:
  /// **'Search songs and folders'**
  String get searchSongsAndFolders;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @caseSensitiveSearchOn.
  ///
  /// In en, this message translates to:
  /// **'Case-sensitive search on'**
  String get caseSensitiveSearchOn;

  /// No description provided for @caseSensitiveSearchOff.
  ///
  /// In en, this message translates to:
  /// **'Case-sensitive search off'**
  String get caseSensitiveSearchOff;

  /// No description provided for @selectSongToView.
  ///
  /// In en, this message translates to:
  /// **'Select a song to view it here.'**
  String get selectSongToView;

  /// No description provided for @noMatchingSongsOrFolders.
  ///
  /// In en, this message translates to:
  /// **'No matching songs or folders.'**
  String get noMatchingSongsOrFolders;

  /// No description provided for @noSongsFound.
  ///
  /// In en, this message translates to:
  /// **'No songs found.'**
  String get noSongsFound;

  /// No description provided for @noLibrarySelected.
  ///
  /// In en, this message translates to:
  /// **'No library selected'**
  String get noLibrarySelected;

  /// No description provided for @rootLabel.
  ///
  /// In en, this message translates to:
  /// **'Root: {path}'**
  String rootLabel(String path);

  /// No description provided for @songsTab.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songsTab;

  /// No description provided for @songTab.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get songTab;

  /// No description provided for @songSelectionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Song selection is not supported on this platform.'**
  String get songSelectionUnsupported;

  /// No description provided for @unableToLoadSong.
  ///
  /// In en, this message translates to:
  /// **'Unable to load song.'**
  String get unableToLoadSong;

  /// No description provided for @noSongSelected.
  ///
  /// In en, this message translates to:
  /// **'No song selected.'**
  String get noSongSelected;

  /// No description provided for @encodingIssues.
  ///
  /// In en, this message translates to:
  /// **'Song contents has encoding issues. Please review.'**
  String get encodingIssues;

  /// No description provided for @libraryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The song library is unavailable. Choose it again.'**
  String get libraryUnavailable;

  /// No description provided for @decreaseTextFontSize.
  ///
  /// In en, this message translates to:
  /// **'Decrease text font size'**
  String get decreaseTextFontSize;

  /// No description provided for @increaseTextFontSize.
  ///
  /// In en, this message translates to:
  /// **'Increase text font size'**
  String get increaseTextFontSize;

  /// No description provided for @transposeDown.
  ///
  /// In en, this message translates to:
  /// **'Transpose down one semitone'**
  String get transposeDown;

  /// No description provided for @resetTransposition.
  ///
  /// In en, this message translates to:
  /// **'Reset transposition'**
  String get resetTransposition;

  /// No description provided for @transposeUp.
  ///
  /// In en, this message translates to:
  /// **'Transpose up one semitone'**
  String get transposeUp;

  /// No description provided for @goToStart.
  ///
  /// In en, this message translates to:
  /// **'Go to start'**
  String get goToStart;

  /// No description provided for @stopScrolling.
  ///
  /// In en, this message translates to:
  /// **'Stop scrolling'**
  String get stopScrolling;

  /// No description provided for @startScrolling.
  ///
  /// In en, this message translates to:
  /// **'Start scrolling'**
  String get startScrolling;

  /// No description provided for @goToEnd.
  ///
  /// In en, this message translates to:
  /// **'Go to end'**
  String get goToEnd;

  /// No description provided for @decreaseScrollSpeed.
  ///
  /// In en, this message translates to:
  /// **'Decrease scroll speed'**
  String get decreaseScrollSpeed;

  /// No description provided for @increaseScrollSpeed.
  ///
  /// In en, this message translates to:
  /// **'Increase scroll speed'**
  String get increaseScrollSpeed;

  /// No description provided for @textFontSize.
  ///
  /// In en, this message translates to:
  /// **'Text font size'**
  String get textFontSize;

  /// No description provided for @transposeSemitones.
  ///
  /// In en, this message translates to:
  /// **'Transpose semitones'**
  String get transposeSemitones;

  /// No description provided for @scrollSpeed.
  ///
  /// In en, this message translates to:
  /// **'Scroll speed'**
  String get scrollSpeed;

  /// No description provided for @gigsTab.
  ///
  /// In en, this message translates to:
  /// **'Gigs'**
  String get gigsTab;

  /// No description provided for @gigs.
  ///
  /// In en, this message translates to:
  /// **'Gigs'**
  String get gigs;

  /// No description provided for @selectGig.
  ///
  /// In en, this message translates to:
  /// **'Select Gig'**
  String get selectGig;

  /// No description provided for @createGig.
  ///
  /// In en, this message translates to:
  /// **'Create Gig'**
  String get createGig;

  /// No description provided for @editGig.
  ///
  /// In en, this message translates to:
  /// **'Edit Gig'**
  String get editGig;

  /// No description provided for @deleteGig.
  ///
  /// In en, this message translates to:
  /// **'Delete Gig'**
  String get deleteGig;

  /// No description provided for @deleteGigConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this gig? Song files will remain untouched.'**
  String get deleteGigConfirmation;

  /// No description provided for @gigTitle.
  ///
  /// In en, this message translates to:
  /// **'Gig Title'**
  String get gigTitle;

  /// No description provided for @gigTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Gig title is required'**
  String get gigTitleRequired;

  /// No description provided for @gigDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get gigDate;

  /// No description provided for @gigVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get gigVenue;

  /// No description provided for @gigNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get gigNotes;

  /// No description provided for @gigStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get gigStartTime;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSet;

  /// No description provided for @renameSet.
  ///
  /// In en, this message translates to:
  /// **'Rename Set'**
  String get renameSet;

  /// No description provided for @deleteSet.
  ///
  /// In en, this message translates to:
  /// **'Delete Set'**
  String get deleteSet;

  /// No description provided for @setTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Title'**
  String get setTitle;

  /// No description provided for @setTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Set title is required'**
  String get setTitleRequired;

  /// No description provided for @setNumber.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String setNumber(int number);

  /// No description provided for @noGigsFound.
  ///
  /// In en, this message translates to:
  /// **'No gigs found. Create one to get started.'**
  String get noGigsFound;

  /// No description provided for @noSetsInGig.
  ///
  /// In en, this message translates to:
  /// **'No sets in this gig.'**
  String get noSetsInGig;

  /// No description provided for @emptySetDropSongsHere.
  ///
  /// In en, this message translates to:
  /// **'Empty set. Drop songs here or select from Songs panel.'**
  String get emptySetDropSongsHere;

  /// No description provided for @addToSet.
  ///
  /// In en, this message translates to:
  /// **'Add to Set'**
  String get addToSet;

  /// No description provided for @addToCurrentSet.
  ///
  /// In en, this message translates to:
  /// **'Add to current set'**
  String get addToCurrentSet;

  /// No description provided for @relinkSong.
  ///
  /// In en, this message translates to:
  /// **'Re-link Song'**
  String get relinkSong;

  /// No description provided for @removeSong.
  ///
  /// In en, this message translates to:
  /// **'Remove Song'**
  String get removeSong;

  /// No description provided for @moveSongUp.
  ///
  /// In en, this message translates to:
  /// **'Move song up'**
  String get moveSongUp;

  /// No description provided for @moveSongDown.
  ///
  /// In en, this message translates to:
  /// **'Move song down'**
  String get moveSongDown;

  /// No description provided for @moveSetUp.
  ///
  /// In en, this message translates to:
  /// **'Move set up'**
  String get moveSetUp;

  /// No description provided for @moveSetDown.
  ///
  /// In en, this message translates to:
  /// **'Move set down'**
  String get moveSetDown;

  /// No description provided for @brokenSongTooltip.
  ///
  /// In en, this message translates to:
  /// **'Song file missing from disk: {path}'**
  String brokenSongTooltip(String path);

  /// No description provided for @duplicateGigTitle.
  ///
  /// In en, this message translates to:
  /// **'A gig with this title already exists.'**
  String get duplicateGigTitle;

  /// No description provided for @duplicateSetTitle.
  ///
  /// In en, this message translates to:
  /// **'A set with this title already exists in this gig.'**
  String get duplicateSetTitle;

  /// No description provided for @duplicateSongInGig.
  ///
  /// In en, this message translates to:
  /// **'This song is already in this gig.'**
  String get duplicateSongInGig;

  /// No description provided for @gigMustHaveAtLeastOneSet.
  ///
  /// In en, this message translates to:
  /// **'A gig must contain at least one set.'**
  String get gigMustHaveAtLeastOneSet;

  /// No description provided for @nextSong.
  ///
  /// In en, this message translates to:
  /// **'Next song'**
  String get nextSong;

  /// No description provided for @previousSong.
  ///
  /// In en, this message translates to:
  /// **'Previous song'**
  String get previousSong;

  /// No description provided for @closeSet.
  ///
  /// In en, this message translates to:
  /// **'Close set'**
  String get closeSet;

  /// No description provided for @unsupportedSongFile.
  ///
  /// In en, this message translates to:
  /// **'The song file type is not supported.'**
  String get unsupportedSongFile;

  /// No description provided for @setNotFound.
  ///
  /// In en, this message translates to:
  /// **'Set not found in this gig.'**
  String get setNotFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
