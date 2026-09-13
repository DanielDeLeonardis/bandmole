import 'package:bandmole/src/features/song_loader/domain/song_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'song_repository_provider_stub.dart'
    if (dart.library.io) 'song_repository_provider_io.dart' as impl;

final Provider<SongRepository> songRepositoryProvider =
    impl.songRepositoryProvider;
