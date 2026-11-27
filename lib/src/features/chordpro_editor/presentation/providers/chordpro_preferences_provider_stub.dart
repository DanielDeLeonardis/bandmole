import 'package:bandmole/src/features/chordpro_editor/data/sqlite_chordpro_preferences_repository.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_preferences_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<ChordProPreferencesRepository>
chordProPreferencesRepositoryProvider =
    Provider<ChordProPreferencesRepository>(
      (_) => SharedPreferencesChordProPreferencesRepository(),
    );
