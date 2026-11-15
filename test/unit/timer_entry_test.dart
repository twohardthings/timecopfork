import 'package:flutter_test/flutter_test.dart';
import 'package:timecop/models/timer_entry.dart';

void main() {
  group('TimerEntry.formatDuration', () {
    final cases = <Duration, String>{
      Duration.zero: '00:00',
      const Duration(seconds: 5): '00:05',
      const Duration(minutes: 3, seconds: 14): '03:14',
      const Duration(minutes: 59, seconds: 59): '59:59',
      const Duration(hours: 1): '1:00:00',
      const Duration(hours: 2, minutes: 10, seconds: 1): '2:10:01',
      const Duration(hours: 26, minutes: 5): '26:05:00',
      const Duration(hours: 123, minutes: 45, seconds: 6): '123:45:06',
    };
    cases.forEach((duration, expected) {
      test('$duration is shown as $expected', () {
        expect(TimerEntry.formatDuration(duration), expected);
      });
    });
  });

  test('formatTime uses the end time of a stopped timer', () {
    final timer = TimerEntry(
      id: 1,
      description: 'a',
      projectID: null,
      startTime: DateTime(2020, 3, 2, 8),
      endTime: DateTime(2020, 3, 2, 9, 30, 15),
    );
    expect(timer.formatTime(), '1:30:15');
  });

  test('formatTime of a running timer counts up to now', () {
    final timer = TimerEntry(
      id: 1,
      description: 'a',
      projectID: null,
      startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      endTime: null,
    );
    expect(timer.formatTime(), startsWith('1:05:0'));
  });

  test('clone keeps the id and replaces only the given fields', () {
    final timer = TimerEntry(
      id: 7,
      description: 'a',
      projectID: 2,
      startTime: DateTime(2020, 3, 2, 8),
      endTime: null,
      notes: 'n',
    );
    final end = DateTime(2020, 3, 2, 9);
    final clone = TimerEntry.clone(timer, description: 'b', endTime: end);
    expect(
      clone,
      TimerEntry(
        id: 7,
        description: 'b',
        projectID: 2,
        startTime: DateTime(2020, 3, 2, 8),
        endTime: end,
        notes: 'n',
      ),
    );
    expect(TimerEntry.clone(timer), timer);
  });
}
