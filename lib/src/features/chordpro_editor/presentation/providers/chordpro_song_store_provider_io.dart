import 'package:bandmole/src/features/chordpro_editor/data/io_chordpro_song_store.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_song_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<ChordProSongStore> chordProSongStoreProvider =
    Provider<ChordProSongStore>((_) => const IoChordProSongStore());
