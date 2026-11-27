import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_preferences_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chordpro_preferences_provider_stub.dart'
    if (dart.library.io) 'chordpro_preferences_provider_io.dart' as impl;

final Provider<ChordProPreferencesRepository>
chordProPreferencesRepositoryProvider =
    impl.chordProPreferencesRepositoryProvider;
