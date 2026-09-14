import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/auto_scrollable_text_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/song_transpose_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/auto_scrollable_text_widget.dart';
import 'package:bandmole/src/core/widgets/tool_tip_raised_button_widget.dart';
import 'package:bandmole/src/core/widgets/tool_tip_rounded_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SongView extends ConsumerWidget {
  final String text;
  final bool canTranspose;

  const SongView({
    super.key,
    required this.text,
    this.canTranspose = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(autoScrollableTextProvider);
    final transposeSemitones = ref.watch(songTransposeProvider);

    void toggleScrolling() {
      ref.read(autoScrollableTextProvider.notifier).toggleIsScrolling();
    }

    void increaseTextFontSize() {
      ref.read(autoScrollableTextProvider.notifier).increaseTextFontSize();
    }

    void decreaseTextFontSize() {
      ref.read(autoScrollableTextProvider.notifier).decreaseTextFontSize();
    }

    void transposeDown() {
      ref.read(songTransposeProvider.notifier).transposeDown();
    }

    void transposeUp() {
      ref.read(songTransposeProvider.notifier).transposeUp();
    }

    void resetTranspose() {
      ref.read(songTransposeProvider.notifier).resetTranspose();
    }

    void increaseScrollSpeed() {
      ref.read(autoScrollableTextProvider.notifier).increaseScrollSpeed();
    }

    void decreaseScrollSpeed() {
      ref.read(autoScrollableTextProvider.notifier).decreaseScrollSpeed();
    }

    void scrollToStart() {
      ref.read(autoScrollableTextProvider.notifier).jumpToStart();
    }

    void scrollToEnd() {
      ref.read(autoScrollableTextProvider.notifier).jumpToEnd();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics'),
      ),
      body: AutoScrollableTextWidget(text: text),
      floatingActionButton: _SongControlsRail(
        textFontSize: model.textFontSize.toInt(),
        transposeSemitones: transposeSemitones,
        canTranspose: canTranspose,
        scrollSpeed: model.scrollSpeed,
        isAtEnd: model.isAtEnd,
        isAtStart: model.isAtStart,
        isScrolling: model.isScrolling,
        onIncreaseTextFontSize: increaseTextFontSize,
        onDecreaseTextFontSize: decreaseTextFontSize,
        onTransposeDown: transposeDown,
        onTransposeUp: transposeUp,
        onResetTranspose: resetTranspose,
        onScrollToEnd: scrollToEnd,
        onToggleScrolling: toggleScrolling,
        onScrollToStart: scrollToStart,
        onIncreaseScrollSpeed: increaseScrollSpeed,
        onDecreaseScrollSpeed: decreaseScrollSpeed,
      ),
    );
  }
}

class _SongControlsRail extends StatelessWidget {
  const _SongControlsRail({
    required this.textFontSize,
    required this.transposeSemitones,
    required this.canTranspose,
    required this.scrollSpeed,
    required this.isAtEnd,
    required this.isAtStart,
    required this.isScrolling,
    required this.onIncreaseTextFontSize,
    required this.onDecreaseTextFontSize,
    required this.onTransposeDown,
    required this.onTransposeUp,
    required this.onResetTranspose,
    required this.onScrollToEnd,
    required this.onToggleScrolling,
    required this.onScrollToStart,
    required this.onIncreaseScrollSpeed,
    required this.onDecreaseScrollSpeed,
  });

  final int textFontSize;
  final int transposeSemitones;
  final bool canTranspose;
  final int scrollSpeed;
  final bool isAtEnd;
  final bool isAtStart;
  final bool isScrolling;
  final VoidCallback onIncreaseTextFontSize;
  final VoidCallback onDecreaseTextFontSize;
  final VoidCallback onTransposeDown;
  final VoidCallback onTransposeUp;
  final VoidCallback onResetTranspose;
  final VoidCallback onScrollToEnd;
  final VoidCallback onToggleScrolling;
  final VoidCallback onScrollToStart;
  final VoidCallback onIncreaseScrollSpeed;
  final VoidCallback onDecreaseScrollSpeed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 140,
            maxHeight: constraints.maxHeight,
          ),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ToolTipRaisedButton(
                    tip: 'Increase text font size',
                    onPressed: onIncreaseTextFontSize,
                    icon: const Icon(Icons.format_size),
                  ),
                  const SizedBox(height: 5),
                  ToolTipRoundedText(
                    text: '$textFontSize',
                    tip: 'Text font size',
                  ),
                  const SizedBox(height: 5),
                  ToolTipRaisedButton(
                    tip: 'Decrease text font size',
                    onPressed: onDecreaseTextFontSize,
                    icon: const Icon(Icons.text_fields),
                  ),
                  const SizedBox(height: 24),
                  ToolTipRaisedButton(
                    tip: 'Transpose down one semitone',
                    onPressed: canTranspose ? onTransposeDown : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  const SizedBox(height: 5),
                  ToolTipRoundedText(
                    text: transposeSemitones == 0
                        ? '0'
                        : '${transposeSemitones > 0 ? '+' : ''}$transposeSemitones',
                    tip: 'Transpose semitones',
                  ),
                  const SizedBox(height: 5),
                  ToolTipRaisedButton(
                    tip: 'Reset transposition',
                    onPressed: canTranspose && transposeSemitones != 0
                        ? onResetTranspose
                        : null,
                    icon: const Icon(Icons.restart_alt),
                  ),
                  const SizedBox(height: 5),
                  ToolTipRaisedButton(
                    tip: 'Transpose up one semitone',
                    onPressed: canTranspose ? onTransposeUp : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const SizedBox(height: 24),
                  ToolTipRaisedButton(
                    tip: 'Go to end',
                    onPressed: isAtEnd ? null : onScrollToEnd,
                    icon: const Icon(Icons.skip_next),
                  ),
                  const SizedBox(height: 10),
                  ToolTipRaisedButton(
                    tip: isScrolling ? 'Stop scrolling' : 'Start scrolling',
                    onPressed: isAtEnd ? null : onToggleScrolling,
                    icon: Icon(isScrolling ? Icons.stop : Icons.play_arrow),
                  ),
                  const SizedBox(height: 10),
                  ToolTipRaisedButton(
                    tip: 'Go to start',
                    onPressed: isAtStart ? null : onScrollToStart,
                    icon: const Icon(Icons.skip_previous),
                  ),
                  const SizedBox(height: 24),
                  ToolTipRaisedButton(
                    tip: 'Increase scroll speed',
                    onPressed: scrollSpeed < 99 ? onIncreaseScrollSpeed : null,
                    icon: const Icon(Icons.fast_forward),
                  ),
                  const SizedBox(height: 5),
                  ToolTipRoundedText(
                    text: '$scrollSpeed',
                    tip: 'Scroll speed',
                  ),
                  const SizedBox(height: 5),
                  ToolTipRaisedButton(
                    tip: 'Decrease scroll speed',
                    onPressed: scrollSpeed > 1 ? onDecreaseScrollSpeed : null,
                    icon: const Icon(Icons.fast_rewind),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
