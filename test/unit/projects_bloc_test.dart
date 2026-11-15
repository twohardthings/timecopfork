import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:timecop/blocs/projects/bloc.dart';
import 'package:timecop/models/project.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemoryDataProvider data;
  late ProjectsBloc bloc;

  Future<ProjectsState> run(ProjectsEvent event) {
    final next = bloc.stream.first;
    bloc.add(event);
    return next;
  }

  setUp(() async {
    data = await sampleData();
    bloc = ProjectsBloc(data);
  });

  tearDown(() => bloc.close());

  test('LoadProjects loads the projects ordered by name', () async {
    final state = await run(LoadProjects());
    expect(state.projects.map((p) => p.name), [
      'Administration',
      'Old project',
      'Time Cop',
    ]);
  });

  test('CreateProject stores the project and keeps the order', () async {
    await run(LoadProjects());
    final state = await run(
      const CreateProject('Bookkeeping', Color(0xFF123456)),
    );
    expect(state.projects.map((p) => p.name), [
      'Administration',
      'Bookkeeping',
      'Old project',
      'Time Cop',
    ]);
    final created = state.projects[1];
    expect(created.colour, const Color(0xFF123456));
    expect(created.archived, isFalse);
    expect(data.projects, contains(created));
  });

  test('EditProject renames, recolours and archives', () async {
    final loaded = await run(LoadProjects());
    final admin = loaded.projects.first;
    final edited = Project.clone(
      admin,
      name: 'Zoo',
      colour: const Color(0xFF000000),
      archived: true,
    );
    final state = await run(EditProject(edited));
    expect(state.projects.last, edited);
    expect(data.projects, contains(edited));
    expect(bloc.getProjectByID(admin.id), edited);
  });

  test('DeleteProject removes the project', () async {
    final loaded = await run(LoadProjects());
    final admin = loaded.projects.first;
    final state = await run(DeleteProject(admin));
    expect(state.projects, hasLength(2));
    expect(bloc.getProjectByID(admin.id), isNull);
    expect(data.projects.any((p) => p.id == admin.id), isFalse);
  });

  test('getProjectByID returns null for null and unknown ids', () async {
    await run(LoadProjects());
    expect(bloc.getProjectByID(null), isNull);
    expect(bloc.getProjectByID(-1), isNull);
    expect(bloc.getProjectByID(1)?.name, 'Time Cop');
  });
}
