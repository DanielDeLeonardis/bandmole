import 'package:bandmole/models/auto_scrollable_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoScrollableTextNotifier extends Notifier<AutoScrollableText> {
  @override
  AutoScrollableText build() => const AutoScrollableText(
        isScrolling: false,
        isAtEnd: false,
        isAtStart: true,
        scrollSpeed: 5,
        textFontSize: 18.0,
      );

  void increaseTextFontSize() {
    state = state.copyWith(
      textFontSize: state.textFontSize + 1.0,
    );
  }

  void decreaseTextFontSize() {
    if (state.textFontSize > 8.0) {
      state = state.copyWith(
        textFontSize: state.textFontSize - 1.0,
      );
    }
  }

  void setPositionState({
    required double screenOffset,
    required double screenMaxExtent,
  }) {
    final isAtStart = screenOffset <= 0.0;
    final isAtEnd = screenOffset >= screenMaxExtent;

    if (state.isAtStart != isAtStart || state.isAtEnd != isAtEnd) {
      state = state.copyWith(
        isAtEnd: isAtEnd,
        isAtStart: isAtStart,
      );
    }
  }

  int increaseScrollSpeed() {
    if (state.scrollSpeed < 99) {
      state = state.copyWith(
        scrollSpeed: state.scrollSpeed + 1,
      );
    }
    return state.scrollSpeed;
  }

  int decreaseScrollSpeed() {
    if (state.scrollSpeed > 1) {
      state = state.copyWith(
        scrollSpeed: state.scrollSpeed - 1,
      );
    }
    return state.scrollSpeed;
  }

  bool toggleIsScrolling() {
    state = state.copyWith(
      isScrolling: !state.isScrolling,
    );
    return state.isScrolling;
  }

  bool setIsScrolling(bool isScrolling) {
    state = state.copyWith(isScrolling: isScrolling);
    return state.isScrolling;
  }

  void jumpToStart() {
    state = state.copyWith(
      isScrolling: false,
      pendingCommand: ScrollCommand.jumpToStart,
    );
  }

  void jumpToEnd() {
    state = state.copyWith(
      isScrolling: false,
      pendingCommand: ScrollCommand.jumpToEnd,
    );
  }

  void clearPendingCommand() {
    if (state.pendingCommand != null) {
      state = state.copyWith(pendingCommand: null);
    }
  }

  void resetScrollState() {
    state = state.copyWith(
      isScrolling: false,
      isAtStart: true,
      isAtEnd: false,
      pendingCommand: null,
    );
  }
}

final autoScrollableTextProvider =
    NotifierProvider<AutoScrollableTextNotifier, AutoScrollableText>(
        AutoScrollableTextNotifier.new);
