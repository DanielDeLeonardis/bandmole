import 'package:bandmole/models/text_event.dart';
import 'package:bandmole/service/auto_scrollable_text_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_scrollable_text_event_provider.g.dart';

@Riverpod(keepAlive: true)
class AutoScrollableTextEvent extends _$AutoScrollableTextEvent {
  late final AutoScrollableTextService _service;

  @override
  Stream<TextEvent> build() {
    _service = AutoScrollableTextService();
    ref.onDispose(() {
      _service.dispose();
    });
    return _service.getStream();
  }

  AutoScrollableTextService get stream => _service;
}
