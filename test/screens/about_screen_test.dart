import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/screens/about/AboutScreen.dart';

import '../helpers/pump_app.dart';

// Regression test: the `about` package was built on the legacy
// package:flutter/material.dart, which the app no longer provides (it uses
// material_ui), so the About screen threw "No Material widget found" /
// "No MaterialLocalizations found" and rendered nothing.
void main() {
  testWidgets('About screen, README page and licenses page render', (
    tester,
  ) async {
    final app = await pumpApp(tester, size: const Size(1080, 2340));
    await app.push(const AboutScreen());
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.text('v1.2.3+4'), findsOneWidget);
    expect(find.text('Readme'), findsOneWidget);
    // the fork's copyright line below the original one; no link to the
    // original project's Weblate
    expect(
      find.textContaining('Time Cop Fork © twohardthings'),
      findsOneWidget,
    );
    expect(find.text('Translate'), findsNothing);
    expect(find.text('Source Code'), findsOneWidget);

    await tester.tap(find.text('Readme'));
    await app.settle(20);
    expect(tester.takeException(), isNull);
    expect(find.byType(Markdown), findsOneWidget);
    expect(find.textContaining('Time Cop', findRichText: true), findsWidgets);

    await tester.pageBack();
    await app.settle(20);
    await tester.tap(find.text('Licenses'));
    await app.settle(20);
    expect(tester.takeException(), isNull);
    expect(find.byType(LicensePage), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
