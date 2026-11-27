import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_song_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chordpro_song_store_provider_stub.dart'
    if (dart.library.io) 'chordpro_song_store_provider_io.dart' as impl;

final Provider<ChordProSongStore> chordProSongStoreProvider =
    impl.chordProSongStoreProvider;
