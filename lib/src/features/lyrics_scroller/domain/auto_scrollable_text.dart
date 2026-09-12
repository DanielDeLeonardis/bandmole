import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_scrollable_text.freezed.dart';

enum ScrollCommand {
  jumpToStart,
  jumpToEnd,
}

@freezed
abstract class AutoScrollableText with _$AutoScrollableText {
  const factory AutoScrollableText({
    required bool isScrolling,
    required bool isAtEnd,
    required bool isAtStart,
    required int scrollSpeed,
    required double textFontSize,
    @Default(null) ScrollCommand? pendingCommand,
  }) = _AutoScrollableText;
}
