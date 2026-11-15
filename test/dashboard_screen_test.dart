import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('shows the stopped timers grouped by day', (tester) async {
    final app = await pumpApp(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Time Cop Fork'), findsOneWidget);
    expect(find.text('UI Layout'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(app.timers.state.timers, hasLength(6));
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

    await tester.tap(find.byTooltip('Stop Timer'));
    await app.settle();
    expect(app.timers.state.countRunningTimers(), 0);
    final data = app.data as InMemoryDataProvider;
    expect(data.timers.last.description, 'Review');
    expect(data.timers.last.endTime, isNotNull);
  });
}
