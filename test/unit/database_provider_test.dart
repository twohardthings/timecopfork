import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timecop/data_providers/data/database_provider.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/models/timer_entry.dart';

import '../helpers/fakes.dart';

void main() {
  late DatabaseProvider db;

  setUpAll(() {
    // the real SQLite library, without a device
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await DatabaseProvider.open(inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  group('projects', () {
    test('create and list, ordered by name', () async {
      final b = await db.createProject(
        name: 'Bravo',
        colour: const Color(0xFF112233),
      );
      final a = await db.createProject(
        name: 'Alpha',
        colour: const Color(0xFF445566),
        archived: true,
      );
      expect(b.id, isNot(a.id));
      expect(await db.listProjects(), [a, b]);
      expect(a.archived, isTrue);
    });

    test('a project without a colour gets a random one', () async {
      await db.createProject(name: 'Any');
      final stored = (await db.listProjects()).single;
      expect(stored.name, 'Any');
      expect(stored.colour.a, 1.0);
    });

    test('edit', () async {
      final p = await db.createProject(
        name: 'Alpha',
        colour: const Color(0xFF112233),
      );
      final edited = Project.clone(
        p,
        name: 'Beta',
        colour: const Color(0xFF000000),
        archived: true,
      );
      await db.editProject(edited);
      expect(await db.listProjects(), [edited]);
    });

    test('deleting a project keeps its timers, without a project', () async {
      final p = await db.createProject(
        name: 'Alpha',
        colour: const Color(0xFF112233),
      );
      await db.createTimer(description: 'work', projectID: p.id);
      await db.deleteProject(p);
      expect(await db.listProjects(), isEmpty);
      final timer = (await db.listTimers()).single;
      expect(timer.description, 'work');
      expect(timer.projectID, isNull);
    });
  });

  group('timers', () {
    test('create and list, ordered by start time', () async {
      final later = await db.createTimer(
        description: 'later',
        startTime: DateTime(2020, 3, 3, 8),
        endTime: DateTime(2020, 3, 3, 9),
        notes: 'some notes',
      );
      final earlier = await db.createTimer(
        description: 'earlier',
        startTime: DateTime(2020, 3, 2, 8),
        endTime: DateTime(2020, 3, 2, 9),
      );
      expect(await db.listTimers(), [earlier, later]);
    });

    test('a timer created without times is running from now', () async {
      final before = DateTime.now();
      final timer = await db.createTimer(description: 'now');
      expect(timer.endTime, isNull);
      expect(timer.startTime.difference(before).inSeconds.abs(), lessThan(5));
      expect((await db.listTimers()).single, timer);
    });

    test('edit', () async {
      final p = await db.createProject(
        name: 'Alpha',
        colour: const Color(0xFF112233),
      );
      final timer = await db.createTimer(description: 'a');
      final edited = TimerEntry(
        id: timer.id,
        description: 'b',
        projectID: p.id,
        startTime: DateTime(2020, 3, 2, 8),
        endTime: DateTime(2020, 3, 2, 9, 30),
        notes: '# Notes',
      );
      await db.editTimer(edited);
      expect((await db.listTimers()).single, edited);
    });

    test('delete', () async {
      final a = await db.createTimer(description: 'a');
      final b = await db.createTimer(description: 'b');
      await db.deleteTimer(a);
      expect(await db.listTimers(), [b]);
    });
  });

  test('import copies projects and timers and maps the project ids', () async {
    // make the ids of the two databases differ
    await db.createProject(name: 'Existing', colour: const Color(0xFF000000));
    final other = await sampleData();

    await db.import(other);

    final projects = await db.listProjects();
    expect(projects.map((p) => p.name), [
      'Administration',
      'Existing',
      'Old project',
      'Time Cop',
    ]);
    final timers = await db.listTimers();
    expect(timers, hasLength(6));
    String? projectOf(String description) {
      final t = timers.firstWhere((t) => t.description == description);
      return projects.where((p) => p.id == t.projectID).firstOrNull?.name;
    }

    expect(projectOf('UI Layout'), 'Time Cop');
    expect(projectOf('Administration'), 'Administration');
    expect(projectOf('Coffee'), isNull);
    final first = timers.first;
    expect(first.startTime, DateTime(2020, 3, 2, 8, 30));
    expect(first.endTime, DateTime(2020, 3, 2, 11));
  });

  group('database files', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('timecop_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('data is still there after closing and reopening', () async {
      final path = '${dir.path}/timecop.db';
      var file = await DatabaseProvider.open(path);
      final p = await file.createProject(
        name: 'Alpha',
        colour: const Color(0xFF112233),
      );
      final t = await file.createTimer(
        description: 'a',
        projectID: p.id,
        startTime: DateTime(2020, 3, 2, 8),
        endTime: DateTime(2020, 3, 2, 9),
        notes: 'n',
      );
      await file.close();

      file = await DatabaseProvider.open(path);
      expect(await file.listProjects(), [p]);
      expect(await file.listTimers(), [t]);
      await file.close();
      expect(await DatabaseProvider.isValidDatabaseFile(path), isTrue);
    });

    test('a version 1 database is upgraded and keeps its data', () async {
      final path = '${dir.path}/old.db';
      final old = await openDatabase(
        path,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            create table projects(
              id integer not null primary key autoincrement,
              name text not null,
              colour int not null
            )''');
          await db.execute('''
            create table timers(
              id integer not null primary key autoincrement,
              project_id integer default null,
              description text not null,
              start_time int not null,
              end_time int default null,
              foreign key(project_id) references projects(id) on delete set null
            )''');
          await db.insert('projects', {'name': 'Old', 'colour': 0xFF112233});
          await db.insert('timers', {
            'project_id': 1,
            'description': 'from v1',
            'start_time': DateTime(2020, 3, 2, 8).millisecondsSinceEpoch,
            'end_time': DateTime(2020, 3, 2, 9).millisecondsSinceEpoch,
          });
        },
      );
      await old.close();

      final upgraded = await DatabaseProvider.open(path);
      expect(await upgraded.listProjects(), const [
        Project(id: 1, name: 'Old', colour: Color(0xFF112233), archived: false),
      ]);
      final timer = (await upgraded.listTimers()).single;
      expect(timer.description, 'from v1');
      expect(timer.projectID, 1);
      expect(timer.notes, isNull);
      // the columns added by the upgrades work
      await upgraded.editTimer(TimerEntry.clone(timer, notes: 'new'));
      await upgraded.editProject(
        Project.clone((await upgraded.listProjects()).single, archived: true),
      );
      expect((await upgraded.listTimers()).single.notes, 'new');
      expect((await upgraded.listProjects()).single.archived, isTrue);
      await upgraded.close();
    });

    test('a file that is not a Time Cop database is not valid', () async {
      final path = '${dir.path}/other.db';
      final other = await openDatabase(path);
      await other.execute('create table something(id integer)');
      await other.close();
      expect(await DatabaseProvider.isValidDatabaseFile(path), isFalse);
    });
  });
}
