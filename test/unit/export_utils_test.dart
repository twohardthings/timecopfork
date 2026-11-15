import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timecop/blocs/projects/bloc.dart';
import 'package:timecop/blocs/settings/bloc.dart';
import 'package:timecop/blocs/timers/bloc.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/utils/export_utils.dart';

import '../helpers/pump_app.dart';

// ExportUtils reads the blocs and translations from a BuildContext, so these
// run inside the app.
void main() {
  /// The exported CSV as rows of cells.
  List<List<dynamic>> export(
    TestApp app, {
    DateTime? start,
    DateTime? end,
    List<Project?>? projects,
  }) {
    final csv = ExportUtils.toCSVString(
      app.context,
      start,
      end,
      projects ?? <Project?>[null, ...app.projects.state.projects],
    );
    return const CsvToListConverter(shouldParseNumbers: false).convert(csv);
  }

  Future<void> set(TestApp app, SetBoolValueEvent event) async {
    app.settingsBloc.add(event);
    await app.settle(2);
  }

  testWidgets('default columns; similar timers of a day are grouped', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    expect(export(app), [
      ['Date', 'Project', 'Description', 'Time (hours)', 'Notes'],
      ['3/2/2020', 'Time Cop', 'UI Layout', '2.5000', ''],
      ['3/2/2020', 'Administration', 'Administration', '1.0000', ''],
      // 4:00 + 0:45, with the notes of the first timer
      ['3/3/2020', 'Time Cop', 'App development', '4.7500', 'Pickers'],
      ['3/4/2020', 'Time Cop', 'Mockups', '1.5000', ''],
      ['3/4/2020', '', 'Coffee', '0.2500', ''],
    ]);
  });

  testWidgets('every field is quoted', (tester) async {
    final app = await pumpApp(tester);
    final csv = ExportUtils.toCSVString(app.context, null, null, [
      ...app.projects.state.projects,
    ]);
    expect(
      csv.split('\r\n').first,
      '"Date","Project","Description","Time (hours)","Notes"',
    );
  });

  testWidgets('without grouping every timer has its own row', (tester) async {
    final app = await pumpApp(tester);
    await set(app, const SetBoolValueEvent(exportGroupTimers: false));
    final rows = export(app);
    expect(rows, hasLength(7));
    expect(rows.where((r) => r[2] == 'App development').map((r) => r[3]), [
      '4.0000',
      '0.7500',
    ]);
  });

  testWidgets('start and end time columns turn grouping off', (tester) async {
    final app = await pumpApp(tester);
    await set(
      app,
      const SetBoolValueEvent(
        exportIncludeStartTime: true,
        exportIncludeEndTime: true,
        exportIncludeProjectDescription: true,
        exportIncludeNotes: false,
      ),
    );
    final rows = export(app);
    expect(rows.first, [
      'Date',
      'Project',
      'Description',
      'Combined Project & Description',
      'Start Time',
      'End Time',
      'Time (hours)',
    ]);
    expect(rows, hasLength(7));
    expect(rows[1], [
      '3/2/2020',
      'Time Cop',
      'UI Layout',
      'Time Cop: UI Layout',
      DateTime(2020, 3, 2, 8, 30).toUtc().toIso8601String(),
      DateTime(2020, 3, 2, 11).toUtc().toIso8601String(),
      '2.5000',
    ]);
  });

  testWidgets('columns can be removed', (tester) async {
    final app = await pumpApp(tester);
    await set(
      app,
      const SetBoolValueEvent(
        exportIncludeDate: false,
        exportIncludeProject: false,
        exportIncludeNotes: false,
      ),
    );
    final rows = export(app);
    expect(rows.first, ['Description', 'Time (hours)']);
    expect(rows[1], ['UI Layout', '2.5000']);
  });

  testWidgets('only the selected projects are exported', (tester) async {
    final app = await pumpApp(tester);
    final admin = app.projects.state.projects.firstWhere(
      (p) => p.name == 'Administration',
    );
    expect(export(app, projects: [admin]).skip(1), [
      ['3/2/2020', 'Administration', 'Administration', '1.0000', ''],
    ]);
    // null stands for "(no project)"
    expect(export(app, projects: [null]).skip(1), [
      ['3/4/2020', '', 'Coffee', '0.2500', ''],
    ]);
    expect(export(app, projects: []), hasLength(1));
  });

  testWidgets('the date range limits the timers', (tester) async {
    final app = await pumpApp(tester);
    final rows = export(
      app,
      start: DateTime(2020, 3, 3),
      end: DateTime(2020, 3, 4),
    );
    expect(rows.skip(1).map((r) => r[0]).toSet(), {'3/3/2020'});
  });

  testWidgets('running timers and archived projects are left out', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final timecop = app.projects.state.projects.firstWhere(
      (p) => p.name == 'Time Cop',
    );
    app.timers.add(const CreateTimer(description: 'still running'));
    app.projects.add(EditProject(Project.clone(timecop, archived: true)));
    await app.settle(3);
    final descriptions = export(app).skip(1).map((r) => r[2]);
    expect(descriptions, ['Administration', 'Coffee']);
  });
}
