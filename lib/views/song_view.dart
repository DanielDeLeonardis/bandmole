import 'package:bandmole/providers/auto_scrollable_text_provider.dart';
import 'package:bandmole/widgets/auto_scrollable_text_widget.dart';
import 'package:bandmole/widgets/tool_tip_raised_button_widget.dart';
import 'package:bandmole/widgets/tool_tip_rounded_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Automatically scroll some text at a specified speed
// Begin the scroll when the button is pressed and stop it when the button is
// pressed again

class SongView extends ConsumerWidget {
  final String text;

  const SongView({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(autoScrollableTextProvider);

    void toggleScrolling() {
      ref.read(autoScrollableTextProvider.notifier).toggleIsScrolling();
    }

    void increaseTextFontSize() {
      ref.read(autoScrollableTextProvider.notifier).increaseTextFontSize();
    }

    void decreaseTextFontSize() {
      ref.read(autoScrollableTextProvider.notifier).decreaseTextFontSize();
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ToolTipRaisedButton(
            tip: 'Increase text font size',
            onPressed: increaseTextFontSize,
            icon: const Icon(Icons.format_size),
          ),
          const SizedBox(height: 5),
          ToolTipRoundedText(
            text: '${model.textFontSize.toInt()}',
            tip: 'Text font size',
          ),
          const SizedBox(height: 5),
          ToolTipRaisedButton(
            tip: 'Decrease text font size',
            onPressed: decreaseTextFontSize,
            icon: const Icon(Icons.text_fields),
          ),
          const SizedBox(height: 30),
          ToolTipRaisedButton(
            tip: 'Go to end',
            onPressed: model.isAtEnd ? null : scrollToEnd,
            icon: const Icon(Icons.skip_next),
          ),
          const SizedBox(height: 10),
          ToolTipRaisedButton(
            tip: model.isScrolling ? 'Stop scrolling' : 'Start scrolling',
            onPressed: model.isAtEnd ? null : toggleScrolling,
            icon: Icon(model.isScrolling ? Icons.stop : Icons.play_arrow),
          ),
          const SizedBox(height: 10),
          ToolTipRaisedButton(
            tip: 'Go to start',
            onPressed: model.isAtStart ? null : scrollToStart,
            icon: const Icon(Icons.skip_previous),
          ),
          const SizedBox(height: 30),
          ToolTipRaisedButton(
            tip: 'Increase scroll speed',
            onPressed: model.scrollSpeed < 99 ? increaseScrollSpeed : null,
            icon: const Icon(Icons.fast_forward),
          ),
          const SizedBox(height: 5),
          ToolTipRoundedText(
            text: '${model.scrollSpeed}',
            tip: 'Scroll speed',
          ),
          const SizedBox(height: 5),
          ToolTipRaisedButton(
            tip: 'Decrease scroll speed',
            onPressed: model.scrollSpeed > 1 ? decreaseScrollSpeed : null,
            icon: const Icon(Icons.fast_rewind),
          ),
        ],
      ),
    );
  }
}
