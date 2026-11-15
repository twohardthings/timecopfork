import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/models/timer_entry.dart';
import 'package:timecop/screens/timer/TimerEditor.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  /// Opens the editor for the sample timer with [description].
  Future<(TestApp, TimerEntry)> openEditor(
    WidgetTester tester,
    String description, {
    bool running = false,
  }) async {
    final app = await pumpApp(
      tester,
      data: await sampleData(withRunningTimer: running),
    );
    final timer = app.timers.state.timers.firstWhere(
      (t) => t.description == description,
    );
    await app.push(TimerEditor(timer: timer));
    expect(tester.takeException(), isNull);
    return (app, timer);
  }

  TimerEntry stored(TestApp app, TimerEntry timer) =>
      (app.data as InMemoryDataProvider).timers.firstWhere(
        (t) => t.id == timer.id,
      );

  testWidgets('shows the timer', (tester) async {
    await openEditor(tester, 'UI Layout');
    expect(find.text('Edit Timer'), findsOneWidget);
    expect(find.text('UI Layout'), findsOneWidget);
    expect(find.text('Time Cop'), findsOneWidget);
    expect(find.textContaining('Mon, Mar 2, 2020 8:30'), findsOneWidget);
    expect(find.textContaining('Mon, Mar 2, 2020 11:00'), findsOneWidget);
    expect(find.text('2:30:00'), findsOneWidget);
  });

  testWidgets('saves a changed description', (tester) async {
    final (app, timer) = await openEditor(tester, 'UI Layout');
    await tester.enterText(find.byType(TextField).first, '  New layout ');
    await tester.tap(find.byKey(const Key('saveDetails')));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TimerEditor), findsNothing);
    // trimmed; everything else unchanged
    expect(
      stored(app, timer),
      TimerEntry.clone(timer, description: 'New layout', notes: null),
    );
    expect(find.text('New layout'), findsOneWidget);
  });

  testWidgets('going back without saving changes nothing', (tester) async {
    final (app, timer) = await openEditor(tester, 'UI Layout');
    await tester.enterText(find.byType(TextField).first, 'Discarded');
    await tester.pageBack();
    await app.settle();
    expect(stored(app, timer), timer);
    expect(find.text('Discarded'), findsNothing);
  });

  testWidgets('changes the project', (tester) async {
    final (app, timer) = await openEditor(tester, 'UI Layout');
    await tester.tap(find.text('Time Cop'));
    await app.settle();
    // archived projects are not offered
    expect(find.text('Old project'), findsNothing);
    await tester.tap(find.text('Administration').last);
    await app.settle();
    await tester.tap(find.byKey(const Key('saveDetails')));
    await app.settle();
    expect(
      app.projects.getProjectByID(stored(app, timer).projectID)?.name,
      'Administration',
    );
  });

  testWidgets('can remove the project', (tester) async {
    final (app, timer) = await openEditor(tester, 'UI Layout');
    await tester.tap(find.text('Time Cop'));
    await app.settle();
    await tester.tap(find.text('(no project)').last);
    await app.settle();
    await tester.tap(find.byKey(const Key('saveDetails')));
    await app.settle();
    expect(stored(app, timer).projectID, isNull);
  });

  testWidgets('edits the notes', (tester) async {
    final (app, timer) = await openEditor(tester, 'App development');
    expect(tester.widget<Markdown>(find.byType(Markdown)).data, 'Pickers');

    await tester.tap(find.text('Notes'));
    await app.settle();
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '# Heading\n\nwith *markdown*\n',
    );
    await tester.tap(find.text('Save'));
    await app.settle();
    expect(
      tester.widget<Markdown>(find.byType(Markdown)).data,
      '# Heading\n\nwith *markdown*',
    );

    await tester.tap(find.byKey(const Key('saveDetails')));
    await app.settle();
    expect(stored(app, timer).notes, '# Heading\n\nwith *markdown*');
  });

  testWidgets('cancelling the notes dialog keeps the notes', (tester) async {
    final (app, _) = await openEditor(tester, 'App development');
    await tester.tap(find.text('Notes'));
    await app.settle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'other',
    );
    await tester.tap(find.text('Cancel'));
    await app.settle();
    expect(tester.widget<Markdown>(find.byType(Markdown)).data, 'Pickers');
  });

  testWidgets('deletes the timer after confirming', (tester) async {
    final (app, timer) = await openEditor(tester, 'Coffee');
    await tester.tap(find.byTooltip('Delete'));
    await app.settle();
    expect(find.text('Confirm Delete'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await app.settle();
    expect(find.byType(TimerEditor), findsOneWidget);
    expect(app.timers.state.timers, contains(timer));

    await tester.tap(find.byTooltip('Delete'));
    await app.settle();
    await tester.tap(find.text('Delete'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TimerEditor), findsNothing);
    expect(app.timers.state.timers, isNot(contains(timer)));
    expect((app.data as InMemoryDataProvider).timers, hasLength(5));
    expect(find.text('Coffee'), findsNothing);
  });

  testWidgets('removing the end time makes the timer run again', (
    tester,
  ) async {
    final (app, timer) = await openEditor(tester, 'Coffee');
    await tester.tap(find.byTooltip('Remove'));
    await app.settle();
    await tester.tap(find.byKey(const Key('saveDetails')));
    await app.settle();
    expect(stored(app, timer).endTime, isNull);
    expect(find.text('Running Timers'), findsOneWidget);
  });

  testWidgets('"set to current time" ends a running timer now', (tester) async {
    final (app, timer) = await openEditor(
      tester,
      'Writing tests',
      running: true,
    );
    expect(timer.endTime, isNull);
    // the menu next to the end time
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await app.settle();
    await tester.tap(find.text('Set to Current Time'));
    await app.settle();
    await tester.tap(find.byKey(const Key('saveDetails')));
    await app.settle();
    final end = stored(app, timer).endTime;
    expect(end, isNotNull);
    expect(DateTime.now().difference(end!).inSeconds.abs(), lessThan(10));
  });
}
