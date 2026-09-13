import 'package:bandmole/main.dart';
import 'package:bandmole/src/features/preferences/presentation/views/preferences_view.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/views/song_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MyApp builds initial route successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Song Search'), findsOneWidget);
  });

  testWidgets('SongView renders lyrics and control buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SongView(text: 'Sample song lyrics text line 1\nLine 2'),
        ),
      ),
    );

    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text('Sample song lyrics text line 1\nLine 2'), findsOneWidget);
    expect(find.byIcon(Icons.format_size), findsOneWidget);
    expect(find.byIcon(Icons.text_fields), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.restart_alt), findsOneWidget);
  });

  testWidgets('SongView allows consecutive font size and scroll speed adjustments',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SongView(text: 'Sample song lyrics text line 1\nLine 2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initial values: font size 18, scroll speed 5
    expect(find.text('18', skipOffstage: false), findsOneWidget);
    expect(find.text('5', skipOffstage: false), findsOneWidget);

    // Tap increase font size multiple times
    await tester.tap(find.byIcon(Icons.format_size));
    await tester.pumpAndSettle();
    expect(find.text('19', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byIcon(Icons.format_size));
    await tester.pumpAndSettle();
    expect(find.text('20', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byIcon(Icons.format_size));
    await tester.pumpAndSettle();
    expect(find.text('21', skipOffstage: false), findsOneWidget);

    // Tap decrease font size multiple times
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    expect(find.text('20', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    expect(find.text('19', skipOffstage: false), findsOneWidget);

    // Tap increase scroll speed multiple times
    await tester.ensureVisible(find.byIcon(Icons.fast_forward));
    await tester.tap(find.byIcon(Icons.fast_forward));
    await tester.pumpAndSettle();
    expect(find.text('6', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byIcon(Icons.fast_forward));
    await tester.pumpAndSettle();
    expect(find.text('7', skipOffstage: false), findsOneWidget);

    // Tap decrease scroll speed multiple times
    await tester.ensureVisible(find.byIcon(Icons.fast_rewind));
    await tester.tap(find.byIcon(Icons.fast_rewind));
    await tester.pumpAndSettle();
    expect(find.text('6', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byIcon(Icons.fast_rewind));
    await tester.pumpAndSettle();
    expect(find.text('5', skipOffstage: false), findsOneWidget);
  });

  testWidgets('SongView start and stop scrolling toggle',
      (WidgetTester tester) async {
    final longLyrics = List.generate(50, (i) => 'Song Line $i').join('\n');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SongView(text: longLyrics),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially play_arrow icon is visible
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // Tap start scrolling
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // Tap stop scrolling
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('SongView go to end and go to start buttons work correctly',
      (WidgetTester tester) async {
    final longLyrics = List.generate(100, (i) => 'Song Line $i').join('\n');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SongView(text: longLyrics),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final goToEndFinder = find.widgetWithIcon(ElevatedButton, Icons.skip_next);
    final goToStartFinder = find.widgetWithIcon(ElevatedButton, Icons.skip_previous);

    // Initially at start: "Go to start" should be disabled, "Go to end" enabled
    expect(tester.widget<ElevatedButton>(goToStartFinder).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(goToEndFinder).onPressed, isNotNull);

    // Tap "Go to end"
    await tester.tap(goToEndFinder);
    await tester.pumpAndSettle();

    // Now at end: "Go to end" should be disabled, "Go to start" enabled
    expect(tester.widget<ElevatedButton>(goToEndFinder).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(goToStartFinder).onPressed, isNotNull);

    // Tap "Go to start"
    await tester.tap(goToStartFinder);
    await tester.pumpAndSettle();

    // Back at start: "Go to start" disabled, "Go to end" enabled
    expect(tester.widget<ElevatedButton>(goToStartFinder).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(goToEndFinder).onPressed, isNotNull);
  });

  testWidgets('SongView go to start stops active scrolling',
      (WidgetTester tester) async {
    final longLyrics = List.generate(100, (i) => 'Song Line $i').join('\n');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SongView(text: longLyrics),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Start scrolling
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // Advance time slightly so it has scrolled down
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    final goToStartFinder = find.widgetWithIcon(ElevatedButton, Icons.skip_previous);
    expect(tester.widget<ElevatedButton>(goToStartFinder).onPressed, isNotNull);

    // Tap "Go to start"
    await tester.tap(goToStartFinder);
    await tester.pumpAndSettle();

    // Scrolling should be stopped (play_arrow icon) and at start
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(tester.widget<ElevatedButton>(goToStartFinder).onPressed, isNull);
  });

  testWidgets('SongView transposes chord charts through the formatter',
      (WidgetTester tester) async {
    const chordSong = '''
{title: Transpose Example}
{start_of_verse}
[Bb]Hello [F]world
''';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SongView(text: chordSong),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transpose Example'), findsOneWidget);
    expect(find.text('Bb'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('B'), findsOneWidget);
    expect(find.text('Bb'), findsNothing);
  });

  testWidgets('PreferenceView displays theme choices',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PreferenceView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preferences'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });
}
