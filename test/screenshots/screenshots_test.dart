@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/models/theme_type.dart';
import 'package:timecop/screens/export/ExportScreen.dart';
import 'package:timecop/screens/projects/ProjectsScreen.dart';
import 'package:timecop/screens/reports/ReportsScreen.dart';
import 'package:timecop/screens/settings/SettingsScreen.dart';
import 'package:timecop/screens/timer/TimerEditor.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

// Renders the store and README screenshots into
// fastlane/metadata/android/en-US/images/phoneScreenshots/, and the store's
// feature graphic for every language in fastlane/metadata/android/*/images/.
//
// Skipped in normal test runs. To update the screenshots, run
//   SCREENSHOTS=1 flutter test test/screenshots
// and review the images before committing them.

/// A 1080 × 2400 phone. (A whole-number logical width, 432, avoids a
/// rounding assertion in the Reports screen's swiper.)
const _pixelRatio = 2.5;
const _size = Size(1080 / _pixelRatio, 2400 / _pixelRatio);
const _outDir = 'fastlane/metadata/android/en-US/images/phoneScreenshots';

void main() {
  final enabled = Platform.environment['SCREENSHOTS'] == '1';

  setUpAll(() async {
    await loadAppFonts();
    await _loadRoboto();
    WidgetsApp.debugAllowBannerOverride = false;
  });

  tearDownAll(() => WidgetsApp.debugAllowBannerOverride = true);

  /// Starts the app with the screenshot data, opens [screen] (if any), lets
  /// [prepare] interact with it, and saves the screen as [name].png.
  void shot(
    String name, {
    ThemeType theme = ThemeType.light,
    Widget Function(InMemoryDataProvider data)? screen,
    Future<void> Function(TestApp app)? prepare,
  }) {
    testWidgets(name, skip: !enabled, (tester) async {
      final data = await _screenshotData();
      final app = await pumpApp(
        tester,
        data: data,
        settings: InMemorySettingsProvider(
          theme: theme,
          locale: const Locale('en'),
        ),
        size: _size,
      );
      if (screen != null) await app.push(screen(data));
      if (prepare != null) await prepare(app);
      await app.settle(20);
      expect(tester.takeException(), isNull);
      await _save(tester, name);
    });
  }

  shot('1-dashboard');
  shot('2-dashboard-dark', theme: ThemeType.dark);
  shot(
    '3-timer-editor',
    screen: (data) => TimerEditor(
      timer: data.timers.firstWhere((t) => (t.notes ?? '').isNotEmpty),
    ),
  );
  shot('4-projects', screen: (_) => const ProjectsScreen());
  shot('5-reports-projects', screen: (_) => const ReportsScreen());
  shot(
    '6-reports-weekly',
    screen: (_) => const ReportsScreen(),
    prepare: (app) async {
      await app.tester.fling(
        find.byType(ReportsScreen),
        const Offset(-300, 0),
        1000,
      );
      await app.settle(15);
    },
  );
  shot('7-export', screen: (_) => const ExportScreen());
  shot('8-settings', screen: (_) => SettingsScreen());

  // The 1024 × 500 banner at the top of the store page, per language. The
  // title comes from the language's title.txt.
  const taglines = <String, String>{
    'en-US': 'Simple private time tracking.',
    'cs': 'Jednoduché a soukromé měření času.',
    'de': 'Einfache, private Zeiterfassung.',
    'es-ES': 'Control del tiempo sencillo y privado.',
    'hu': 'Egyszerű, privát időkövetés.',
    'it-IT': 'Semplice monitoraggio del tempo privato.',
    'nb-NO': 'Enkel og privat tidsregistrering.',
    'tr': 'Basit ve gizli zaman takibi.',
  };
  for (final entry in taglines.entries) {
    testWidgets('feature graphic ${entry.key}', skip: !enabled, (tester) async {
      final dir = 'fastlane/metadata/android/${entry.key}';
      final title = File('$dir/title.txt').readAsStringSync().trim();
      await _saveFeatureGraphic(
        tester,
        title,
        entry.value,
        '$dir/images/featureGraphic.png',
      );
    });
  }
}

Future<void> _saveFeatureGraphic(
  WidgetTester tester,
  String title,
  String tagline,
  String path,
) async {
  tester.view.physicalSize = const Size(1024, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  const white = Color(0xFFFFFFFF);
  await tester.pumpWidget(
    RepaintBoundary(
      key: appBoundaryKey,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF263238),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // long titles (e.g. Spanish) shrink to fit
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset('icon.no-bg.color.svg', height: 88),
                      const SizedBox(width: 22),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'PublicSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 92,
                          color: white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tagline,
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 44,
                      color: white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  // the SVG loads asynchronously
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  final boundary =
      tester.renderObject(find.byKey(appBoundaryKey)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

/// Saves the whole app at the phone's resolution.
Future<void> _save(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject(find.byKey(appBoundaryKey)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_outDir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

/// Text without an explicit font (e.g. Markdown notes) uses the system font,
/// Roboto on Android. Flutter's SDK ships it for its own tests.
Future<void> _loadRoboto() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final loader = FontLoader('Roboto');
  for (final style in ['Regular', 'Medium', 'Bold']) {
    final file = File('${dir.path}/Roboto-$style.ttf');
    if (file.existsSync()) {
      loader.addFont(
        Future.value(ByteData.sublistView(await file.readAsBytes())),
      );
    }
  }
  await loader.load();
}

/// Three weeks of plausible work up to today, plus two running timers.
Future<InMemoryDataProvider> _screenshotData() async {
  final data = InMemoryDataProvider();
  final app = await data.createProject(
    name: 'Time Cop Fork',
    colour: const Color(0xFF8E24AA),
  );
  final admin = await data.createProject(
    name: 'Administration',
    colour: const Color(0xFFD81B60),
  );
  final website = await data.createProject(
    name: 'Website',
    colour: const Color(0xFF00897B),
  );
  await data.createProject(
    name: 'Old client',
    colour: const Color(0xFF7CB342),
    archived: true,
  );

  final rand = Random(7);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var notesAdded = false;
  for (var daysAgo = 20; daysAgo >= 1; daysAgo--) {
    final day = today.subtract(Duration(days: daysAgo));
    if (day.weekday > DateTime.friday) continue;
    Future<void> add(
      String description,
      int project,
      int hour,
      int minute,
      int minutes, {
      String? notes,
    }) {
      final start = day.add(Duration(hours: hour, minutes: minute));
      return data.createTimer(
        description: description,
        projectID: project,
        startTime: start,
        endTime: start.add(Duration(minutes: minutes)),
        notes: notes,
      );
    }

    final devTask = [
      'App development',
      'UI layout',
      'Bug fixing',
    ][rand.nextInt(3)];
    final notes = !notesAdded && devTask == 'Bug fixing'
        ? '## Date pickers\n\n'
              'Start and end time pickers didn\'t open.\n\n'
              '- updated the picker package\n'
              '- added a regression test\n'
              '- checked on **Android 15**'
        : null;
    notesAdded |= notes != null;
    await add(
      devTask,
      app.id,
      8,
      rand.nextInt(45),
      150 + rand.nextInt(90),
      notes: notes,
    );
    await add('Emails', admin.id, 13, rand.nextInt(20), 25 + rand.nextInt(40));
    if (rand.nextBool()) {
      await add(
        'Blog post',
        website.id,
        14,
        30 + rand.nextInt(20),
        45 + rand.nextInt(75),
      );
    } else {
      await add(devTask, app.id, 14, rand.nextInt(30), 90 + rand.nextInt(60));
    }
  }
  await data.createTimer(
    description: 'Store screenshots',
    projectID: website.id,
    startTime: now.subtract(const Duration(hours: 1, minutes: 12, seconds: 9)),
  );
  await data.createTimer(
    description: 'Coffee',
    startTime: now.subtract(const Duration(minutes: 4, seconds: 31)),
  );
  return data;
}
