import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';
import 'package:bandmole/src/features/song_groups/presentation/song_group_error_localizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every song-group error code to localized English', () {
    final localizations = EnglishAppLocalizations();
    final expectedMessages = <SongGroupErrorCode, String>{
      SongGroupErrorCode.gigTitleRequired: 'Gig title is required',
      SongGroupErrorCode.duplicateGigTitle:
          'A gig with this title already exists.',
      SongGroupErrorCode.setTitleRequired: 'Set title is required',
      SongGroupErrorCode.duplicateSetTitle:
          'A set with this title already exists in this gig.',
      SongGroupErrorCode.duplicateSongInGig: 'This song is already in this gig.',
      SongGroupErrorCode.unsupportedSongFile:
          'The song file type is not supported.',
      SongGroupErrorCode.gigMustHaveAtLeastOneSet:
          'A gig must contain at least one set.',
      SongGroupErrorCode.setNotFound: 'Set not found in this gig.',
    };

    for (final entry in expectedMessages.entries) {
      expect(
        songGroupErrorMessage(localizations, SongGroupException(entry.key)),
        entry.value,
      );
    }
  });
}