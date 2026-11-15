import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/screens/projects/ProjectEditor.dart';
import 'package:timecop/screens/projects/ProjectsScreen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  Future<TestApp> openProjects(WidgetTester tester) async {
    final app = await pumpApp(tester);
    await app.push(const ProjectsScreen());
    expect(tester.takeException(), isNull);
    return app;
  }

  Project stored(TestApp app, String name) => (app.data as InMemoryDataProvider)
      .projects
      .firstWhere((p) => p.name == name);

  final archivedIcon = find.byIcon(FontAwesomeIcons.boxArchive.data);

  Finder tile(String name) => find.widgetWithText(ListTile, name);

  testWidgets('lists all projects and marks archived ones', (tester) async {
    await openProjects(tester);
    for (final name in ['Administration', 'Old project', 'Time Cop']) {
      expect(tile(name), findsOneWidget);
    }
    expect(
      find.descendant(of: tile('Old project'), matching: archivedIcon),
      findsOneWidget,
    );
    expect(archivedIcon, findsOneWidget);
  });

  testWidgets('creates a project', (tester) async {
    final app = await openProjects(tester);
    await tester.tap(find.byKey(const Key('addProject')));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.text('Create New Project'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), ' Bookkeeping ');
    await tester.tap(find.byType(CircleColor).first);
    await app.settle();
    await tester.tap(find.text('Create'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ProjectEditor), findsNothing);
    expect(tile('Bookkeeping'), findsOneWidget);
    final created = stored(app, 'Bookkeeping');
    expect(created.archived, isFalse);
    // the tapped colour, not the editor's initial near-white
    expect(created.colour, isNot(Colors.grey[50]));
  });

  testWidgets('a project needs a name', (tester) async {
    final app = await openProjects(tester);
    await tester.tap(find.byKey(const Key('addProject')));
    await app.settle();
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Create'));
    await app.settle();
    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.byType(ProjectEditor), findsOneWidget);
    expect(app.projects.state.projects, hasLength(3));

    await tester.tap(find.text('Cancel'));
    await app.settle();
    expect(find.byType(ProjectEditor), findsNothing);
    expect(app.projects.state.projects, hasLength(3));
  });

  testWidgets('renames a project', (tester) async {
    final app = await openProjects(tester);
    final before = stored(app, 'Administration');
    await tester.tap(tile('Administration'));
    await app.settle();
    expect(find.text('Edit Project'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Office');
    await tester.tap(find.text('Save'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(tile('Office'), findsOneWidget);
    expect(tile('Administration'), findsNothing);
    expect(stored(app, 'Office'), Project.clone(before, name: 'Office'));
  });

  testWidgets('archives and unarchives from the menu', (tester) async {
    final app = await openProjects(tester);
    await tester.tap(
      find.descendant(
        of: tile('Time Cop'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await app.settle();
    await tester.tap(find.text('Archive'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(stored(app, 'Time Cop').archived, isTrue);
    expect(archivedIcon, findsNWidgets(2));

    await tester.tap(
      find.descendant(
        of: tile('Time Cop'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await app.settle();
    await tester.tap(find.text('Unarchive'));
    await app.settle();
    expect(stored(app, 'Time Cop').archived, isFalse);
  });

  testWidgets('swiping left shows the archive action', (tester) async {
    final app = await openProjects(tester);
    await tester.drag(tile('Administration'), const Offset(-200, 0));
    await app.settle();
    await tester.tap(find.byType(SlidableAction));
    await app.settle();
    expect(stored(app, 'Administration').archived, isTrue);
  });

  testWidgets('deletes a project after confirming', (tester) async {
    final app = await openProjects(tester);
    Future<void> chooseDelete() async {
      await tester.tap(
        find.descendant(
          of: tile('Administration'),
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await app.settle();
      await tester.tap(find.text('Delete'));
      await app.settle();
    }

    await chooseDelete();
    expect(find.text('Confirm Delete'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await app.settle();
    expect(app.projects.state.projects, hasLength(3));

    await chooseDelete();
    await tester.tap(find.text('Delete'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(tile('Administration'), findsNothing);
    final data = app.data as InMemoryDataProvider;
    expect(data.projects.map((p) => p.name), ['Time Cop', 'Old project']);
  });

  testWidgets('timers of an archived project leave the dashboard', (
    tester,
  ) async {
    final app = await openProjects(tester);
    await tester.tap(
      find.descendant(
        of: tile('Administration'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await app.settle();
    await tester.tap(find.text('Archive'));
    await app.settle();
    await tester.pageBack();
    await app.settle();
    expect(find.text('UI Layout'), findsOneWidget);
    expect(find.text('Administration'), findsNothing);
  });
}
