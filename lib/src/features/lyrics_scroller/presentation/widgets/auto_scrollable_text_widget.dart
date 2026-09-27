import 'dart:math';

import 'package:bandmole/src/features/lyrics_scroller/domain/auto_scrollable_text.dart';
import 'package:bandmole/src/features/lyrics_scroller/domain/song_formatting.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/auto_scrollable_text_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/song_transpose_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/song_text_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoScrollableTextWidget extends ConsumerStatefulWidget {
  final String text;

  const AutoScrollableTextWidget({super.key, required this.text});

  @override
  ConsumerState<AutoScrollableTextWidget> createState() =>
      _AutoScrollableTextWidgetState();
}

class _AutoScrollableTextWidgetState
    extends ConsumerState<AutoScrollableTextWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late final AutoScrollableTextNotifier _textNotifier;
  ProviderSubscription<AutoScrollableText>? _autoScrollableTextSubscription;

  @override
  void initState() {
    super.initState();
    _textNotifier = ref.read(autoScrollableTextProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    _autoScrollableTextSubscription = ref.listenManual(
      autoScrollableTextProvider,
      (previous, next) {
        if (previous == null) {
          return;
        }

        final command = next.pendingCommand;
        if (command != null) {
          _schedulePostFrame(() {
            _textNotifier.clearPendingCommand();
            switch (command) {
              case ScrollCommand.jumpToStart:
                _scrollToStart();
                break;
              case ScrollCommand.jumpToEnd:
                _scrollToEnd();
                break;
            }
          });
        } else if (previous.isScrolling != next.isScrolling) {
          _scrollToggleAnimate(
            scrollSpeed: next.scrollSpeed,
            isScrolling: next.isScrolling,
          );
        } else if (next.isScrolling &&
            previous.scrollSpeed != next.scrollSpeed) {
          _scroll(next.scrollSpeed);
        }
      },
    );

    _schedulePostFrame(() {
      _textNotifier.resetScrollState();
      _updatePositionState();
    });
  }

  @override
  void didChangeMetrics() {
    _schedulePostFrame(_updatePositionState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollableTextSubscription?.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _schedulePostFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      action();
    });
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
    final duration = (remaining / (scrollSpeed * 2.5)).toInt();
    return duration < 1 ? 1 : duration;
  }

  void _scrollAnimate({required int duration, required double offset}) {
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
    final transposeSemitones = ref.watch(songTransposeProvider);
    final song = SongFormatter.parse(
      widget.text,
      transposeSemitones: transposeSemitones,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final nextIsAtStart = _scrollController.offset <= 1.0;
      final nextIsAtEnd = _scrollController.position.maxScrollExtent <= 0.0
          ? true
          : _scrollController.offset >=
                (_scrollController.position.maxScrollExtent - 1.0);

      if (model.isAtStart != nextIsAtStart || model.isAtEnd != nextIsAtEnd) {
        _updatePositionState();
      }
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (!_scrollController.hasClients) return false;

        if (scrollNotification is ScrollEndNotification) {
          _schedulePostFrame(() {
            if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent) {
              _textNotifier.setIsScrolling(false);
            }
          });
        }

        if (scrollNotification is UserScrollNotification &&
            scrollNotification.direction != ScrollDirection.idle) {
          if (model.isScrolling) {
            _schedulePostFrame(() {
              _textNotifier.setIsScrolling(false);
            });
          }
        }

        _schedulePostFrame(_updatePositionState);

        return true;
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SongTextRenderer(song: song, fontSize: model.textFontSize),
        ),
      ),
    );
  }
}
