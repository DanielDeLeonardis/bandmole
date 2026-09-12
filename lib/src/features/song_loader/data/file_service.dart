import 'dart:convert';
import 'dart:io';

import 'package:bandmole/src/features/song_loader/domain/song.dart';

Future<Song> getSong(File file) async {
  var isMalformed = false;
  String? songText;

  final bytes = await file.readAsBytes();

  try {
    songText = utf8.decode(
      bytes.buffer.asUint8List(),
    );
  } catch (e) {
    try {
      songText = utf8.decode(
        bytes.buffer.asUint8List(),
        allowMalformed: true,
      );
      isMalformed = true;
    } catch (e) {
      isMalformed = true;
    }
  }
  return Song(
    file: file,
    text: songText,
    isMalformed: isMalformed,
  );
}
