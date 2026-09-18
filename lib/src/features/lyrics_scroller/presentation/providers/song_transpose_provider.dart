import 'package:flutter_riverpod/flutter_riverpod.dart';

class SongTransposeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void transposeUp() {
    state += 1;
  }

  void transposeDown() {
    state -= 1;
  }

  void resetTranspose() {
    state = 0;
  }
}

final songTransposeProvider =
    NotifierProvider<SongTransposeNotifier, int>(SongTransposeNotifier.new);
