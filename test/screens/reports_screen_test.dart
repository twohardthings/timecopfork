import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/screens/reports/ReportsScreen.dart';
import 'package:timecop/screens/reports/components/WeeklyTotals.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  Future<TestApp> openReports(WidgetTester tester) async {
    final app = await pumpApp(tester);
    await app.push(const ReportsScreen());
    expect(tester.takeException(), isNull);
    return app;
  }

  /// The hours of each slice of the project breakdown chart.
  /// Empty when there is nothing to show (the chart is then left out).
  List<double> slices(WidgetTester tester) => tester
      .widgetList<PieChart>(find.byType(PieChart))
      .expand((chart) => chart.data.sections)
      .map((s) => s.value)
      .toList();

  Future<void> nextPage(TestApp app) async {
    await app.tester.fling(
      find.byType(ReportsScreen),
      const Offset(-300, 0),
      1000,
    );
    await app.settle(15);
  }

  testWidgets('starts with the share of each project', (tester) async {
    await openReports(tester);
    expect(find.byKey(const Key('projectBreakdown')), findsOneWidget);
    expect(find.text('Total Project Share'), findsOneWidget);
    // 0:15 without a project, 1:00 administration, 8:45 Time Cop
    expect(slices(tester), unorderedEquals([0.25, 1.0, 8.75]));
    // the legend names every project that is not archived
    for (final name in ['(no project)', 'Administration', 'Time Cop']) {
      expect(find.widgetWithText(Chip, name), findsOneWidget);
    }
    expect(find.text('Old project'), findsNothing);
  });

  testWidgets('swiping shows the other reports', (tester) async {
    final app = await openReports(tester);
    await nextPage(app);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('weeklyTotals')), findsOneWidget);
    expect(find.text('Weekly Hours'), findsOneWidget);
    // one date label per week, numbers only on the left and bottom
    final titles = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .titlesData;
    expect(titles.bottomTitles.sideTitles.interval, 1);
    expect(
      tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .gridData
          .verticalInterval,
      1,
    );
    expect(titles.topTitles.sideTitles.showTitles, isFalse);
    expect(titles.rightTitles.sideTitles.showTitles, isFalse);

    await nextPage(app);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('weekdayAverages')), findsOneWidget);
    expect(find.text('Average Daily Hours'), findsOneWidget);

    await nextPage(app);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('timeTable')), findsOneWidget);
    final table = find.byKey(const Key('timeTable'));
    Finder inTable(String text) =>
        find.descendant(of: table, matching: find.text(text));
    expect(inTable('Time Cop'), findsOneWidget);
    expect(inTable('8.8'), findsOneWidget);
    expect(inTable('Administration'), findsOneWidget);
    expect(inTable('1.0'), findsOneWidget);
    expect(inTable('(no project)'), findsOneWidget);
    expect(inTable('0.3'), findsOneWidget);
    expect(inTable('Total'), findsOneWidget);
    expect(inTable('10.0'), findsOneWidget);
  });

  test('the weekly chart labels every week, or fewer for long ranges', () {
    expect(weekLabelInterval(0), 1);
    expect(weekLabelInterval(2), 1);
    expect(weekLabelInterval(6), 1);
    expect(weekLabelInterval(7), 2);
    expect(weekLabelInterval(12), 2);
    expect(weekLabelInterval(52), 9);
  });

  testWidgets('a year of data gets about six date labels', (tester) async {
    final data = InMemoryDataProvider();
    final project = await data.createProject(name: 'Work');
    final start = DateTime(2025, 1, 6, 9);
    for (var week = 0; week < 52; week++) {
      final day = start.add(Duration(days: week * 7));
      await data.createTimer(
        description: 'w$week',
        projectID: project.id,
        startTime: day,
        endTime: day.add(const Duration(hours: 3)),
      );
    }
    final app = await pumpApp(tester, data: data);
    await app.push(const ReportsScreen());
    await nextPage(app);
    expect(tester.takeException(), isNull);
    final chart = tester.widget<LineChart>(find.byType(LineChart)).data;
    expect(chart.titlesData.bottomTitles.sideTitles.interval, 9);
    expect(chart.gridData.verticalInterval, 9);
  });

  testWidgets('unselected projects are left out', (tester) async {
    final app = await openReports(tester);
    await tester.tap(find.text('Projects'));
    await app.settle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Time Cop'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(slices(tester), unorderedEquals([0.25, 1.0]));

    await tester.tap(find.text('Select None'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(slices(tester), isEmpty);
  });

  testWidgets('"Select All" selects every project again', (tester) async {
    final app = await openReports(tester);
    await tester.tap(find.text('Projects'));
    await app.settle();
    await tester.tap(find.text('Select None'));
    await app.settle();
    await tester.tap(find.text('Select All'));
    await app.settle();
    expect(slices(tester), unorderedEquals([0.25, 1.0, 8.75]));
  });

  testWidgets('a quick filter limits the period', (tester) async {
    final app = await openReports(tester);
    // the sample data is from 2020, so nothing is left in "this month"
    await tester.tap(find.text('This month'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(slices(tester), isEmpty);
    expect(find.text('--'), findsNothing);

    // removing the start date shows everything again
    await tester.tap(find.byTooltip('Remove').first);
    await app.settle();
    await tester.tap(find.byTooltip('Remove').first);
    await app.settle();
    expect(slices(tester), hasLength(3));
  });

  testWidgets('works without any timers', (tester) async {
    final app = await pumpApp(tester, data: InMemoryDataProvider());
    await app.push(const ReportsScreen());
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 3; i++) {
      await nextPage(app);
      expect(tester.takeException(), isNull);
    }
    expect(find.byKey(const Key('timeTable')), findsOneWidget);
  });
}
