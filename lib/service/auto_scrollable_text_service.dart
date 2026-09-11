import 'dart:async';

import 'package:bandmole/models/text_event.dart';

class AutoScrollableTextService {
  final _events = StreamController<TextEvent>.broadcast();

  Stream<TextEvent> getStream() {
    return _events.stream;
  }

  void dispose() {
    _events.close();
  }

  void addEvent(TextEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}

