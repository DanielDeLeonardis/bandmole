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
