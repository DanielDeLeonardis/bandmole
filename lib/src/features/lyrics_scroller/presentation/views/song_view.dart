import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/auto_scrollable_text_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/song_transpose_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/auto_scrollable_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/l10n/app_localizations_fallback.dart';

class SongView extends ConsumerWidget {
  final String text;
  final bool canTranspose;
  final bool embedded;

  const SongView({
    super.key,
    required this.text,
    this.canTranspose = true,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        EnglishAppLocalizations();
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

    final songBody = Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(right: 176),
            child: AutoScrollableTextWidget(text: text),
          ),
        ),
        Positioned(
          right: 12,
          top: 8,
          bottom: 8,
          child: SizedBox(
            width: 160,
            child: _SongControlsRail(
              buttonColor: Theme.of(context).primaryColor,
              textFontSize: model.textFontSize.toInt(),
              transposeSemitones: transposeSemitones,
              canTranspose: canTranspose,
              scrollSpeed: model.scrollSpeed,
              isAtEnd: model.isAtEnd,
              isAtStart: model.isAtStart,
              isScrolling: model.isScrolling,
              canAdjustScrollSpeed: !(model.isAtStart && model.isAtEnd),
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
              l10n: l10n,
            ),
          ),
        ),
      ],
    );

    if (embedded) {
      return songBody;
    }

    return Scaffold(appBar: AppBar(), body: songBody);
  }
}

class _SongControlsRail extends StatelessWidget {
  const _SongControlsRail({
    required this.buttonColor,
    required this.textFontSize,
    required this.transposeSemitones,
    required this.canTranspose,
    required this.scrollSpeed,
    required this.isAtEnd,
    required this.isAtStart,
    required this.isScrolling,
    required this.canAdjustScrollSpeed,
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
    required this.l10n,
  });

  final Color buttonColor;
  final int textFontSize;
  final int transposeSemitones;
  final bool canTranspose;
  final int scrollSpeed;
  final bool isAtEnd;
  final bool isAtStart;
  final bool isScrolling;
  final bool canAdjustScrollSpeed;
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
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controls = Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  tip: l10n.decreaseTextFontSize,
                  icon: Icons.text_fields,
                  onPressed: onDecreaseTextFontSize,
                ),
                _controlValue('$textFontSize', l10n.textFontSize),
                _controlButton(
                  tip: l10n.increaseTextFontSize,
                  icon: Icons.format_size,
                  onPressed: onIncreaseTextFontSize,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  tip: l10n.transposeDown,
                  icon: Icons.remove_circle_outline,
                  onPressed: canTranspose ? onTransposeDown : null,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _controlValue(
                      transposeSemitones == 0
                          ? '0'
                          : '${transposeSemitones > 0 ? '+' : ''}$transposeSemitones',
                      l10n.transposeSemitones,
                    ),
                    _controlButton(
                      tip: l10n.resetTransposition,
                      icon: Icons.restart_alt,
                      onPressed: canTranspose && transposeSemitones != 0
                          ? onResetTranspose
                          : null,
                    ),
                  ],
                ),
                _controlButton(
                  tip: l10n.transposeUp,
                  icon: Icons.add_circle_outline,
                  onPressed: canTranspose ? onTransposeUp : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  tip: l10n.goToStart,
                  icon: Icons.skip_previous,
                  onPressed: isAtStart ? null : onScrollToStart,
                ),
                _controlButton(
                  tip: isScrolling ? l10n.stopScrolling : l10n.startScrolling,
                  icon: isScrolling ? Icons.stop : Icons.play_arrow,
                  onPressed: isAtEnd ? null : onToggleScrolling,
                ),
                _controlButton(
                  tip: l10n.goToEnd,
                  icon: Icons.skip_next,
                  onPressed: isAtEnd ? null : onScrollToEnd,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  tip: l10n.decreaseScrollSpeed,
                  icon: Icons.fast_rewind,
                  onPressed: canAdjustScrollSpeed && scrollSpeed > 1
                      ? onDecreaseScrollSpeed
                      : null,
                ),
                _controlValue('$scrollSpeed', l10n.scrollSpeed),
                _controlButton(
                  tip: l10n.increaseScrollSpeed,
                  icon: Icons.fast_forward,
                  onPressed: canAdjustScrollSpeed && scrollSpeed < 99
                      ? onIncreaseScrollSpeed
                      : null,
                ),
              ],
            ),
          ],
        );

        if (constraints.maxHeight < 280) {
          return SingleChildScrollView(
            child: SizedBox(height: 280, child: controls),
          );
        }

        return controls;
      },
    );
  }

  Widget _controlButton({
    required String tip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tip,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          minimumSize: const Size.square(44),
          maximumSize: const Size.square(44),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }

  Widget _controlValue(String value, String tip) {
    return Tooltip(
      message: tip,
      child: SizedBox(
        width: 44,
        child: Text(value, textAlign: TextAlign.center),
      ),
    );
  }
}
