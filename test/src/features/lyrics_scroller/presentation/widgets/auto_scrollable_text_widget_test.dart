import 'package:bandmole/src/features/lyrics_scroller/presentation/providers/auto_scrollable_text_provider.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/auto_scrollable_text_widget.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/song_text_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AutoScrollableTextWidget handles scrolling commands and text updates', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final longText = List.generate(200, (index) => 'Verse line $index').join('\n');
    final scrollableFinder = find.descendant(
      of: find.byType(AutoScrollableTextWidget),
      matching: find.byType(Scrollable),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 160,
              child: AutoScrollableTextWidget(text: longText),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final renderer = tester.widget<SongTextRenderer>(find.byType(SongTextRenderer));
    expect(renderer.allowMultiColumnLayout, isFalse);

    ScrollableState scrollableState() =>
        tester.state<ScrollableState>(scrollableFinder);

    expect(
      scrollableState().position.maxScrollExtent,
      greaterThan(0),
    );

    final notifier = container.read(autoScrollableTextProvider.notifier);
    notifier.setIsScrolling(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(autoScrollableTextProvider).isScrolling, isTrue);

    notifier.increaseScrollSpeed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(autoScrollableTextProvider).scrollSpeed, 6);

    scrollableState().position.jumpTo(scrollableState().position.maxScrollExtent);
    await tester.pump();
    expect(scrollableState().position.pixels, greaterThan(0));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 160,
              child: AutoScrollableTextWidget(text: '$longText\nFinal line'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(scrollableState().position.pixels, 0);
  });
}
