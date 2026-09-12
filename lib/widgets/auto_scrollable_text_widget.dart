import 'dart:math';
import 'package:bandmole/models/auto_scrollable_text.dart';
import 'package:bandmole/providers/auto_scrollable_text_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Automatically scroll text at a specified speed
class AutoScrollableTextWidget extends ConsumerStatefulWidget {
  final String text;

  const AutoScrollableTextWidget({
    super.key,
    required this.text,
  });

  @override
  ConsumerState<AutoScrollableTextWidget> createState() =>
      _AutoScrollableTextWidgetState();
}

class _AutoScrollableTextWidgetState
    extends ConsumerState<AutoScrollableTextWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AutoScrollableTextNotifier _textNotifier;

  @override
  void initState() {
    super.initState();
    _textNotifier = ref.read(autoScrollableTextProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _textNotifier.resetScrollState();
        _updatePositionState();
      }
    });
  }

  @override
  void dispose() {
    _textNotifier.setIsScrolling(false);
    _scrollController.dispose();
    super.dispose();
  }

  void _updatePositionState() {
    if (mounted && _scrollController.hasClients) {
      _textNotifier.setPositionState(
            screenOffset: _scrollController.offset,
            screenMaxExtent: _scrollController.position.maxScrollExtent,
          );
    }
  }

  int _calcScrollDuration({
    required double screenMaxExtent,
    required double screenOffset,
    required int scrollSpeed,
  }) {
    if (scrollSpeed <= 0) return 1;
    final remaining = screenMaxExtent - screenOffset;
    if (remaining <= 0) return 0;
    final duration = (remaining / (scrollSpeed * 10)).toInt();
    return duration < 1 ? 1 : duration;
  }

  void _scrollAnimate({
    required int duration,
    required double offset,
  }) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      offset,
      duration: Duration(seconds: max(1, duration)),
      curve: Curves.linear,
    );
  }

  void _scroll(int scrollSpeed) {
    if (!_scrollController.hasClients) return;

    final scrollDuration = _calcScrollDuration(
      screenMaxExtent: _scrollController.position.maxScrollExtent,
      screenOffset: _scrollController.offset,
      scrollSpeed: scrollSpeed,
    );

    if (scrollDuration > 0) {
      _scrollAnimate(
        duration: scrollDuration,
        offset: _scrollController.position.maxScrollExtent,
      );
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients &&
        _scrollController.offset < _scrollController.position.maxScrollExtent) {
      _textNotifier.setIsScrolling(false);
      _scrollAnimate(
        duration: 1,
        offset: _scrollController.position.maxScrollExtent,
      );
    }
  }

  void _scrollToStart() {
    if (_scrollController.hasClients &&
        _scrollController.offset > _scrollController.position.minScrollExtent) {
      _textNotifier.setIsScrolling(false);
      _scrollAnimate(
        duration: 1,
        offset: _scrollController.position.minScrollExtent,
      );
    }
  }

  void _stopScroll() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.offset);
  }

  void _scrollToggleAnimate({
    required int scrollSpeed,
    required bool isScrolling,
  }) {
    if (!_scrollController.hasClients) return;
    if (isScrolling) {
      _scroll(scrollSpeed);
    } else {
      _stopScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(autoScrollableTextProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePositionState());

    ref.listen(autoScrollableTextProvider, (previous, next) {
      if (previous == null) return;
      if (next.pendingCommand != null) {
        final command = next.pendingCommand!;
        _textNotifier.clearPendingCommand();
        switch (command) {
          case ScrollCommand.jumpToStart:
            _scrollToStart();
            break;
          case ScrollCommand.jumpToEnd:
            _scrollToEnd();
            break;
        }
      } else if (previous.isScrolling != next.isScrolling) {
        _scrollToggleAnimate(
          scrollSpeed: next.scrollSpeed,
          isScrolling: next.isScrolling,
        );
      } else if (next.isScrolling && previous.scrollSpeed != next.scrollSpeed) {
        _scroll(next.scrollSpeed);
      }
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (!_scrollController.hasClients) return false;

        if (scrollNotification is ScrollEndNotification) {
          if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent) {
            _textNotifier.setIsScrolling(false);
          }
        }

        if (scrollNotification is UserScrollNotification &&
            scrollNotification.direction != ScrollDirection.idle) {
          if (model.isScrolling) {
            _textNotifier.setIsScrolling(false);
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updatePositionState();
        });

        return true;
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Text(
            widget.text,
            maxLines: 1000,
            style: TextStyle(
              fontSize: model.textFontSize,
              fontFamily: 'Consolas',
            ),
          ),
        ),
      ),
    );
  }
}
