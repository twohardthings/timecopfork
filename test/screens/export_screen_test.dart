import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/screens/export/ExportScreen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  late RecordingFilePicker files;
  late FilePickerPlatform realFilePicker;

  setUp(() {
    realFilePicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = files = RecordingFilePicker();
  });

  tearDown(() => FilePickerPlatform.instance = realFilePicker);

  Future<TestApp> openExport(WidgetTester tester) async {
    final app = await pumpApp(tester);
    await app.push(const ExportScreen());
    expect(tester.takeException(), isNull);
    return app;
  }

  Future<List<String>> exportCsv(TestApp app) async {
    files.saved.clear();
    await app.tester.tap(find.text('To CSV'));
    await app.settle();
    expect(app.tester.takeException(), isNull);
    final file = files.saved.single;
    expect(file.mimeType, 'text/csv');
    expect(file.fileName, matches(r'^timecop_\d{4}-\d\d-\d\d\.csv$'));
    return const LineSplitter().convert(utf8.decode(file.bytes));
  }

  Finder switchOf(String title) => find.descendant(
    of: find.widgetWithText(SwitchListTile, title),
    matching: find.byType(Switch),
  );

  testWidgets('exports all timers as CSV', (tester) async {
    final app = await openExport(tester);
    final lines = await exportCsv(app);
    expect(
      lines.first,
      '"Date","Project","Description","Time (hours)","Notes"',
    );
    expect(lines, hasLength(6));
    expect(lines[1], '"3/2/2020","Time Cop","UI Layout","2.5000",""');
  });

  testWidgets('the column switches change the export and are stored', (
    tester,
  ) async {
    final app = await openExport(tester);
    await tester.tap(find.text('Columns'));
    await app.settle();
    await tester.tap(switchOf('Date'));
    await tester.tap(switchOf('Notes'));
    await tester.tap(switchOf('Start Time'));
    await app.settle();
    expect(tester.takeException(), isNull);

    final settings = app.settings as InMemorySettingsProvider;
    expect(settings.values['exportIncludeDate'], isFalse);
    expect(settings.values['exportIncludeNotes'], isFalse);
    expect(settings.values['exportIncludeStartTime'], isTrue);
    expect(tester.widget<Switch>(switchOf('Date')).value, isFalse);

    final lines = await exportCsv(app);
    expect(lines.first, '"Project","Description","Start Time","Time (hours)"');
    // with a start time column the timers are no longer grouped
    expect(lines, hasLength(7));
  });

  testWidgets('"Group Similar Timers" can be turned off', (tester) async {
    final app = await openExport(tester);
    await tester.tap(find.text('Options'));
    await app.settle();
    await tester.tap(switchOf('Group Similar Timers Per Day'));
    await app.settle();
    expect(app.settingsBloc.state.exportGroupTimers, isFalse);
    expect(await exportCsv(app), hasLength(7));
  });

  testWidgets('only the selected projects are exported', (tester) async {
    final app = await openExport(tester);
    await tester.tap(find.text('Projects'));
    await app.settle();
    Finder box(String name) => find.widgetWithText(CheckboxListTile, name);
    // archived projects can't be chosen
    expect(box('Old project'), findsNothing);

    await tester.tap(box('Time Cop'));
    await app.settle();
    var lines = await exportCsv(app);
    expect(lines.skip(1).map((l) => l.split(',')[2]), [
      '"Administration"',
      '"Coffee"',
    ]);

    await tester.tap(find.text('Select None'));
    await app.settle();
    expect(
      tester.widget<CheckboxListTile>(box('Administration')).value,
      isFalse,
    );
    expect(await exportCsv(app), hasLength(1));

    await tester.tap(find.text('Select All'));
    await app.settle();
    for (final name in ['(no project)', 'Administration', 'Time Cop']) {
      expect(tester.widget<CheckboxListTile>(box(name)).value, isTrue);
    }
    lines = await exportCsv(app);
    expect(lines, hasLength(6));
  });

  testWidgets('a quick filter limits the exported period', (tester) async {
    final app = await openExport(tester);
    // the sample data is from 2020
    await tester.tap(find.text('This month'));
    await app.settle();
    expect(await exportCsv(app), hasLength(1));
  });

  testWidgets('exports a PDF', (tester) async {
    final app = await openExport(tester);
    await tester.tap(find.text('To PDF'));
    await app.settle(30);
    expect(tester.takeException(), isNull);
    final file = files.saved.single;
    expect(file.mimeType, 'application/pdf');
    expect(file.fileName, endsWith('.pdf'));
    expect(ascii.decode(file.bytes.sublist(0, 5)), '%PDF-');
    expect(file.bytes.length, greaterThan(1000));
  });

  testWidgets('the database menu offers import and export', (tester) async {
    final app = await openExport(tester);
    await tester.tap(find.byKey(const Key('exportMenuButton')));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('exportMenuImport')), findsOneWidget);
    expect(find.byKey(const Key('exportMenuExport')), findsOneWidget);
  });
}
