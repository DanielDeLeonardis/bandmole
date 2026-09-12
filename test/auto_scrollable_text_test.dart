import 'package:bandmole/src/features/lyrics_scroller/domain/auto_scrollable_text.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/auto_scrollable_text_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('AutoScrollableTextNotifier initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(autoScrollableTextProvider);
    expect(state.isScrolling, isFalse);
    expect(state.isAtStart, isTrue);
    expect(state.isAtEnd, isFalse);
    expect(state.scrollSpeed, equals(5));
    expect(state.textFontSize, equals(18.0));
    expect(state.pendingCommand, isNull);
  });

  test('Font size increase and decrease within bounds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(autoScrollableTextProvider.notifier);

    notifier.increaseTextFontSize();
    expect(container.read(autoScrollableTextProvider).textFontSize, equals(19.0));

    notifier.decreaseTextFontSize();
    expect(container.read(autoScrollableTextProvider).textFontSize, equals(18.0));

    // Decrease below lower bound (8.0)
    for (int i = 0; i < 20; i++) {
      notifier.decreaseTextFontSize();
    }
    expect(container.read(autoScrollableTextProvider).textFontSize, equals(8.0));
  });

  test('Scroll speed bounds check (1 to 99)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(autoScrollableTextProvider.notifier);

    notifier.increaseScrollSpeed();
    expect(container.read(autoScrollableTextProvider).scrollSpeed, equals(6));

    notifier.decreaseScrollSpeed();
    expect(container.read(autoScrollableTextProvider).scrollSpeed, equals(5));

    // Speed min boundary
    for (int i = 0; i < 10; i++) {
      notifier.decreaseScrollSpeed();
    }
    expect(container.read(autoScrollableTextProvider).scrollSpeed, equals(1));

    // Speed max boundary
    for (int i = 0; i < 150; i++) {
      notifier.increaseScrollSpeed();
    }
    expect(container.read(autoScrollableTextProvider).scrollSpeed, equals(99));
  });

  test('setPositionState only updates state when boundary flags change', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(autoScrollableTextProvider.notifier);

    // Initial state isAtStart: true, isAtEnd: false
    notifier.setPositionState(screenOffset: 0.0, screenMaxExtent: 100.0);
    expect(container.read(autoScrollableTextProvider).isAtStart, isTrue);

    // Scroll to middle
    notifier.setPositionState(screenOffset: 50.0, screenMaxExtent: 100.0);
    expect(container.read(autoScrollableTextProvider).isAtStart, isFalse);
    expect(container.read(autoScrollableTextProvider).isAtEnd, isFalse);

    // Scroll to end
    notifier.setPositionState(screenOffset: 100.0, screenMaxExtent: 100.0);
    expect(container.read(autoScrollableTextProvider).isAtEnd, isTrue);
  });

  test('resetScrollState resets scroll flags while preserving user preferences', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(autoScrollableTextProvider.notifier);

    // Modify speed and font size
    notifier.increaseTextFontSize(); // 19.0
    notifier.increaseScrollSpeed(); // 6
    notifier.toggleIsScrolling(); // true
    notifier.setPositionState(screenOffset: 100.0, screenMaxExtent: 100.0); // isAtEnd: true, isAtStart: false

    expect(container.read(autoScrollableTextProvider).textFontSize, equals(19.0));
    expect(container.read(autoScrollableTextProvider).scrollSpeed, equals(6));
    expect(container.read(autoScrollableTextProvider).isScrolling, isTrue);
    expect(container.read(autoScrollableTextProvider).isAtEnd, isTrue);
    expect(container.read(autoScrollableTextProvider).isAtStart, isFalse);

    // Reset scroll state
    notifier.resetScrollState();

    final resetState = container.read(autoScrollableTextProvider);
    expect(resetState.textFontSize, equals(19.0));
    expect(resetState.scrollSpeed, equals(6));
    expect(resetState.isScrolling, isFalse);
    expect(resetState.isAtStart, isTrue);
    expect(resetState.isAtEnd, isFalse);
    expect(resetState.pendingCommand, isNull);
  });

  test('jumpToStart, jumpToEnd, and clearPendingCommand update state correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(autoScrollableTextProvider.notifier);

    // Initially pendingCommand is null
    expect(container.read(autoScrollableTextProvider).pendingCommand, isNull);

    // Start scrolling then jumpToEnd
    notifier.toggleIsScrolling();
    expect(container.read(autoScrollableTextProvider).isScrolling, isTrue);

    notifier.jumpToEnd();
    final endState = container.read(autoScrollableTextProvider);
    expect(endState.isScrolling, isFalse);
    expect(endState.pendingCommand, equals(ScrollCommand.jumpToEnd));

    // Clear pending command
    notifier.clearPendingCommand();
    expect(container.read(autoScrollableTextProvider).pendingCommand, isNull);

    // jumpToStart
    notifier.jumpToStart();
    final startState = container.read(autoScrollableTextProvider);
    expect(startState.isScrolling, isFalse);
    expect(startState.pendingCommand, equals(ScrollCommand.jumpToStart));

    // clearPendingCommand
    notifier.clearPendingCommand();
    expect(container.read(autoScrollableTextProvider).pendingCommand, isNull);
  });
}
