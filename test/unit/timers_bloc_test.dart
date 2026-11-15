import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:timecop/blocs/timers/bloc.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/models/timer_entry.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemoryDataProvider data;
  late InMemorySettingsProvider settings;
  late RecordingNotificationsProvider notifications;
  late TimersBloc bloc;

  /// Adds [event] and waits for the state it produces.
  Future<TimersState> run(TimersEvent event) {
    final next = bloc.stream.first;
    bloc.add(event);
    return next;
  }

  setUp(() async {
    data = await sampleData();
    settings = InMemorySettingsProvider();
    notifications = RecordingNotificationsProvider();
    bloc = TimersBloc(data, settings, notifications);
  });

  tearDown(() => bloc.close());

  test('starts empty', () {
    expect(bloc.state.timers, isEmpty);
    expect(bloc.state.countRunningTimers(), 0);
  });

  test('LoadTimers loads the stored timers ordered by start time', () async {
    final state = await run(LoadTimers());
    expect(state.timers, hasLength(6));
    expect(state.timers.map((t) => t.description).first, 'UI Layout');
    final starts = state.timers.map((t) => t.startTime).toList();
    expect(starts, [...starts]..sort());
  });

  test('CreateTimer stores a running timer with the project', () async {
    await run(LoadTimers());
    const project = Project(
      id: 1,
      name: 'Time Cop',
      colour: Color(0xFF00ACC1),
      archived: false,
    );
    final state = await run(
      const CreateTimer(description: 'Review', project: project),
    );
    expect(state.timers, hasLength(7));
    expect(state.countRunningTimers(), 1);
    final created = state.timers.last;
    expect(created.description, 'Review');
    expect(created.projectID, 1);
    expect(created.endTime, isNull);
    expect(data.timers, contains(created));
  });

  test('StopTimer sets the end time and stores it', () async {
    await run(LoadTimers());
    final started = (await run(const CreateTimer(description: 'x')))
        .timers
        .last;
    final state = await run(StopTimer(started));
    expect(state.countRunningTimers(), 0);
    final stopped = state.timers.firstWhere((t) => t.id == started.id);
    expect(stopped.endTime, isNotNull);
    expect(
      data.timers.firstWhere((t) => t.id == started.id).endTime,
      isNotNull,
    );
  });

  test('StopAllTimers stops every running timer and no other', () async {
    await run(LoadTimers());
    await run(const CreateTimer(description: 'x'));
    final before = (await run(const CreateTimer(description: 'y'))).timers;
    expect(before.where((t) => t.endTime == null), hasLength(2));

    final state = await run(const StopAllTimers());
    expect(state.countRunningTimers(), 0);
    expect(data.timers.where((t) => t.endTime == null), isEmpty);
    // the timers that were already stopped keep their end time
    for (final t in before.where((t) => t.endTime != null)) {
      expect(state.timers, contains(t));
    }
  });

  test('EditTimer replaces the timer and keeps the list sorted', () async {
    final loaded = await run(LoadTimers());
    final last = loaded.timers.last;
    final edited = TimerEntry(
      id: last.id,
      description: 'Moved',
      projectID: last.projectID,
      startTime: DateTime(2019, 1, 1, 8),
      endTime: DateTime(2019, 1, 1, 9),
      notes: 'note',
    );
    final state = await run(EditTimer(edited));
    expect(state.timers, hasLength(6));
    expect(state.timers.first, edited);
    expect(data.timers, contains(edited));
  });

  test('DeleteTimer removes the timer', () async {
    final loaded = await run(LoadTimers());
    final victim = loaded.timers[2];
    final state = await run(DeleteTimer(victim));
    expect(state.timers, hasLength(5));
    expect(state.timers, isNot(contains(victim)));
    expect(data.timers, isNot(contains(victim)));
  });

  test('UpdateNow moves the clock forward but keeps the timers', () async {
    final loaded = await run(LoadTimers());
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final state = await run(const UpdateNow());
    expect(state.timers, loaded.timers);
    expect(state.now.isAfter(loaded.now), isTrue);
  });
}
