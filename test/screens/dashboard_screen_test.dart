import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/screens/projects/ProjectsScreen.dart';
import 'package:timecop/screens/timer/TimerEditor.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('shows the stopped timers grouped by day', (tester) async {
    final app = await pumpApp(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Time Cop Fork'), findsOneWidget);
    for (final day in [
      'Mon, Mar 2, 2020',
      'Tue, Mar 3, 2020',
      'Wed, Mar 4, 2020',
    ]) {
      expect(find.text(day), findsOneWidget);
    }
    expect(find.text('UI Layout'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    // two similar timers of one day are shown as one row with their total
    expect(find.text('App development'), findsOneWidget);
    expect(find.text('4:45:00'), findsNWidgets(2));
    expect(find.text('Running Timers'), findsNothing);
    expect(app.timers.state.timers, hasLength(6));
  });

  testWidgets('a grouped row expands to its timers', (tester) async {
    final app = await pumpApp(tester);
    await tester.tap(find.text('App development'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.text('4:00:00'), findsOneWidget);
    expect(find.text('45:00'), findsOneWidget);
  });

  testWidgets('without grouping every timer has its own row', (tester) async {
    await pumpApp(
      tester,
      settings: InMemorySettingsProvider()
        ..values.addAll({'defaultFilterDays': -1, 'groupTimers': false}),
    );
    expect(find.text('App development'), findsNWidgets(2));
  });

  testWidgets('"show project names" names the project of every timer', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      settings: InMemorySettingsProvider()
        ..values.addAll({'defaultFilterDays': -1, 'showProjectNames': true}),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Time Cop'), findsWidgets);
    expect(find.text('(no project)'), findsOneWidget);
    // the grouped row still expands
    await tester.tap(find.text('App development'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.text('45:00'), findsOneWidget);
  });

  testWidgets('"collapse days" folds older days until they are tapped', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      settings: InMemorySettingsProvider()
        ..values.addAll({'defaultFilterDays': -1, 'collapseDays': true}),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Monday, March 2, 2020'), findsOneWidget);
    expect(find.text('UI Layout'), findsNothing);

    await tester.tap(find.text('Monday, March 2, 2020'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.text('UI Layout'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing);
  });

  testWidgets('starts and stops a timer', (tester) async {
    final app = await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Review');
    await tester.tap(find.byKey(const Key('startTimerButton')));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(app.timers.state.countRunningTimers(), 1);
    expect(find.text('Running Timers'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    // the description field is emptied for the next timer
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );

    await tester.tap(find.byTooltip('Stop Timer'));
    await app.settle();
    expect(app.timers.state.countRunningTimers(), 0);
    expect(find.text('Running Timers'), findsNothing);
    final data = app.data as InMemoryDataProvider;
    expect(data.timers.last.description, 'Review');
    expect(data.timers.last.endTime, isNotNull);
  });

  testWidgets('starts a timer for the chosen project', (tester) async {
    final app = await pumpApp(tester);
    await tester.tap(find.byTooltip('Project'));
    await app.settle();
    // archived projects are not offered
    expect(find.text('Old project'), findsNothing);
    await tester.tap(find.text('Administration').last);
    await app.settle();
    expect(find.byTooltip('Project (Administration)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('startTimerButton')));
    await app.settle();
    final running = app.timers.state.timers.singleWhere(
      (t) => t.endTime == null,
    );
    expect(
      app.projects.getProjectByID(running.projectID)?.name,
      'Administration',
    );
  });

  testWidgets('"stop all" stops every running timer', (tester) async {
    final app = await pumpApp(
      tester,
      data: await sampleData(withRunningTimer: true),
    );
    expect(find.text('Writing tests'), findsOneWidget);
    // while a timer runs, the button is a menu
    await tester.tap(find.byTooltip('Timer Menu'));
    await app.settle();
    await tester.tap(find.byTooltip('Start New Timer'));
    await app.settle();
    expect(app.timers.state.countRunningTimers(), 2);

    await tester.tap(find.byTooltip('Timer Menu'));
    await app.settle();
    await tester.tap(find.byTooltip('Stop All Timers'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(app.timers.state.countRunningTimers(), 0);
  });

  testWidgets('with "one timer at a time", starting stops the others', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      data: await sampleData(withRunningTimer: true),
      settings: InMemorySettingsProvider()
        ..values.addAll({'defaultFilterDays': -1, 'oneTimerAtATime': true}),
    );
    // with one timer running, the button stops it
    expect(find.byKey(const Key('stopAllTimersButton')), findsOneWidget);
    // resuming an old timer stops the running one
    await tester.drag(find.text('Coffee'), const Offset(-200, 0));
    await app.settle();
    await tester.tap(find.byType(SlidableAction));
    await app.settle();
    final running = app.timers.state.timers.where((t) => t.endTime == null);
    expect(running.map((t) => t.description), ['Coffee']);

    await tester.tap(find.byKey(const Key('stopAllTimersButton')));
    await app.settle();
    expect(app.timers.state.countRunningTimers(), 0);
    expect(find.byKey(const Key('startTimerButton')), findsOneWidget);
  });

  testWidgets('the description field suggests earlier descriptions', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'moc');
    await app.settle();
    expect(tester.takeException(), isNull);
    // once in the list of timers and once as a suggestion
    expect(find.text('Mockups'), findsNWidgets(2));

    await tester.tap(find.text('Mockups').last);
    await app.settle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mockups',
    );
  });

  testWidgets('resuming a stopped timer starts a copy of it', (tester) async {
    final app = await pumpApp(tester);
    // swipe the row to the left to show its "resume" action
    await tester.drag(find.text('Coffee'), const Offset(-200, 0));
    await app.settle();
    await tester.tap(find.byType(SlidableAction));
    await app.settle();
    expect(tester.takeException(), isNull);
    final running = app.timers.state.timers.singleWhere(
      (t) => t.endTime == null,
    );
    expect(running.description, 'Coffee');
    expect(find.text('Running Timers'), findsOneWidget);
  });

  testWidgets('search shows only matching timers', (tester) async {
    final app = await pumpApp(tester);
    await tester.tap(find.byTooltip('Search'));
    await app.settle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      ),
      'admin',
    );
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('UI Layout'), findsNothing);

    await tester.tap(find.byTooltip('Cancel').first);
    await app.settle();
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Time Cop Fork'), findsOneWidget);
  });

  testWidgets('the filter hides the timers of unselected projects', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await tester.tap(find.byTooltip('Filter'));
    await app.settle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Projects'));
    await app.settle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Time Cop'));
    await app.settle();
    // close the sheet
    await tester.tapAt(const Offset(200, 20));
    await app.settle();

    expect(find.text('UI Layout'), findsNothing);
    expect(find.text('Mockups'), findsNothing);
    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('the default filter hides timers older than 30 days', (
    tester,
  ) async {
    // the app's real default settings; the sample data is from 2020
    final app = await pumpApp(
      tester,
      data: await sampleData(withRunningTimer: true),
      settings: InMemorySettingsProvider(),
    );
    expect(app.timers.state.timers, hasLength(7));
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('Writing tests'), findsOneWidget);
  });

  testWidgets('tapping a timer opens the editor', (tester) async {
    final app = await pumpApp(tester);
    await tester.tap(find.text('Mockups'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TimerEditor), findsOneWidget);
    expect(find.text('Edit Timer'), findsOneWidget);
  });

  testWidgets('the menu opens every screen', (tester) async {
    final app = await pumpApp(tester);
    const titles = {
      'menuProjects': 'Projects',
      'menuReports': 'Reports',
      'menuExport': 'Import and Export',
      'menuSettings': 'Settings',
      'menuAbout': 'About',
    };
    for (final entry in titles.entries) {
      await app.openMenu(entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(entry.value),
        ),
        findsOneWidget,
        reason: entry.key,
      );
      await tester.pageBack();
      await app.settle();
    }
    expect(find.byType(ProjectsScreen), findsNothing);
  });

  testWidgets('a wide window uses the wide layout', (tester) async {
    await pumpApp(tester, size: const Size(1280, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('UI Layout'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsWidgets);
  });
}
