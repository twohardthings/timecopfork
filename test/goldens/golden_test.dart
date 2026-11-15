@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/models/theme_type.dart';
import 'package:timecop/screens/export/ExportScreen.dart';
import 'package:timecop/screens/projects/ProjectsScreen.dart';
import 'package:timecop/screens/reports/ReportsScreen.dart';
import 'package:timecop/screens/settings/SettingsScreen.dart';
import 'package:timecop/screens/timer/TimerEditor.dart';

import '../helpers/fakes.dart';
import '../helpers/golden.dart';
import '../helpers/pump_app.dart';

// Golden tests compare a screen with a reference image in `images/`.
// After an intended change of the look, update the images with
//   flutter test --update-goldens --tags golden
// and review them like code.
void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldenComparator();
    // the "DEBUG" banner would cover the top right corner
    WidgetsApp.debugAllowBannerOverride = false;
  });

  tearDownAll(() => WidgetsApp.debugAllowBannerOverride = true);

  final screens = <String, Widget? Function(InMemoryDataProvider)>{
    'dashboard': (_) => null,
    'timer_editor': (data) =>
        TimerEditor(timer: data.timers.firstWhere((t) => t.notes == 'Pickers')),
    'projects': (_) => const ProjectsScreen(),
    'reports': (_) => const ReportsScreen(),
    'export': (_) => const ExportScreen(),
    'settings': (_) => SettingsScreen(),
  };

  // every screen in the light and dark themes, plus Spanish for its long
  // texts
  const variants = <String, (ThemeType, Locale)>{
    'light': (ThemeType.light, Locale('en')),
    'dark': (ThemeType.dark, Locale('en')),
    'es': (ThemeType.light, Locale('es')),
  };

  for (final screen in screens.entries) {
    for (final variant in variants.entries) {
      testWidgets('${screen.key} (${variant.key})', (tester) async {
        final data = await sampleData();
        final (theme, locale) = variant.value;
        final app = await pumpApp(
          tester,
          data: data,
          settings: InMemorySettingsProvider(theme: theme, locale: locale)
            ..values['defaultFilterDays'] = -1,
        );
        final widget = screen.value(data);
        if (widget != null) await app.push(widget);
        await app.settle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('images/${screen.key}_${variant.key}.png'),
        );
      });
    }
  }
}
