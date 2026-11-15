import 'package:flutter_test/flutter_test.dart';
import 'package:timecop/screens/timer/TimerEditor.dart';

import '../helpers/pump_app.dart';

// Regression test: flutter_datetime_picker_plus 2.x used the legacy
// package:flutter/material.dart localizations, which the app no longer
// provides (it uses material_ui), so the pickers threw "No
// MaterialLocalizations found" and never opened.
void main() {
  testWidgets('Timer editor rows open the date/time pickers', (tester) async {
    final app = await pumpApp(tester);
    final timer = app.timers.state.timers.firstWhere((t) => t.endTime != null);
    await app.push(TimerEditor(timer: timer));

    for (final label in ['Start Time', 'End Time', 'Duration']) {
      await tester.tap(find.text(label));
      await app.settle();
      expect(tester.takeException(), isNull, reason: label);
      expect(
        find.text('Done'),
        findsOneWidget,
        reason: '$label: picker sheet not shown',
      );
      await tester.tap(find.text('Cancel'));
      await app.settle();
      expect(find.text('Done'), findsNothing);
    }
  });
}
