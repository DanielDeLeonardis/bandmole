import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/song_groups/domain/song_group_utils.dart';

String songGroupErrorMessage(
  AppLocalizations l10n,
  SongGroupException exception,
) => switch (exception.code) {
  SongGroupErrorCode.gigTitleRequired => l10n.gigTitleRequired,
  SongGroupErrorCode.duplicateGigTitle => l10n.duplicateGigTitle,
  SongGroupErrorCode.setTitleRequired => l10n.setTitleRequired,
  SongGroupErrorCode.duplicateSetTitle => l10n.duplicateSetTitle,
  SongGroupErrorCode.duplicateSongInGig => l10n.duplicateSongInGig,
  SongGroupErrorCode.unsupportedSongFile => l10n.unsupportedSongFile,
  SongGroupErrorCode.gigMustHaveAtLeastOneSet =>
    l10n.gigMustHaveAtLeastOneSet,
  SongGroupErrorCode.setNotFound => l10n.setNotFound,
};