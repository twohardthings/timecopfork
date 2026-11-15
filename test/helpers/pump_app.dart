import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timecop/blocs/locale/locale_bloc.dart';
import 'package:timecop/blocs/notifications/notifications_bloc.dart';
import 'package:timecop/blocs/projects/projects_bloc.dart';
import 'package:timecop/blocs/settings/bloc.dart';
import 'package:timecop/blocs/theme/theme_bloc.dart';
import 'package:timecop/blocs/timers/timers_bloc.dart';
import 'package:timecop/data_providers/data/data_provider.dart';
import 'package:timecop/data_providers/notifications/notifications_provider.dart';
import 'package:timecop/data_providers/settings/settings_provider.dart';
import 'package:timecop/main.dart' as app;

import 'fakes.dart';

/// The [RepaintBoundary] around the whole app, for capturing screenshots.
const appBoundaryKey = ValueKey('appBoundary');

/// A phone-sized test window, in logical pixels.
const Size phoneSize = Size(412, 915);

/// The running app under test and the fakes behind it.
class TestApp {
  final WidgetTester tester;
  final DataProvider data;
  final SettingsProvider settings;
  final NotificationsProvider notifications;

  TestApp(this.tester, this.data, this.settings, this.notifications);

  BuildContext get context => tester.element(find.byType(Scaffold).first);

  TimersBloc get timers => BlocProvider.of<TimersBloc>(context);
  ProjectsBloc get projects => BlocProvider.of<ProjectsBloc>(context);
  SettingsBloc get settingsBloc => BlocProvider.of<SettingsBloc>(context);
  ThemeBloc get theme => BlocProvider.of<ThemeBloc>(context);
  LocaleBloc get locale => BlocProvider.of<LocaleBloc>(context);

  /// Lets real asynchronous work (asset loading, the fake providers, bloc
  /// events) finish and rebuilds, without waiting for animations that never
  /// end (the app updates running timers every second).
  Future<void> settle([int rounds = 10]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pushes [screen] on top of the dashboard.
  Future<void> push(Widget screen) async {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    await settle();
  }

  /// Opens the dashboard's menu and taps the entry with [key], e.g.
  /// `menuProjects`.
  Future<void> openMenu(String key) async {
    await tester.tap(find.byKey(const Key('menuButton')));
    await settle();
    await tester.tap(find.byKey(Key(key)));
    await settle();
  }
}

/// Starts the whole app the way `main()` does, with in-memory providers.
///
/// Every call builds fresh providers and blocs, and the window size is reset
/// when the test ends, so tests don't influence each other.
Future<TestApp> pumpApp(
  WidgetTester tester, {
  DataProvider? data,
  SettingsProvider? settings,
  NotificationsProvider? notifications,
  Size size = phoneSize,
}) async {
  // The asset bundle caches the futures of loaded assets. A future created in
  // an earlier test belongs to that test's (finished) fake-async zone and
  // never completes in this one, which leaves the app stuck loading its
  // translations. Start every test with an empty cache.
  rootBundle.clear();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  PackageInfo.setMockInitialValues(
    appName: 'Time Cop Fork',
    packageName: 'io.github.twohardthings.timecopfork',
    version: '1.2.3',
    buildNumber: '4',
    buildSignature: '',
  );

  final d = data ?? await sampleData();
  // the sample data is from 2020, so by default don't filter the dashboard
  // to the last 30 days
  final s =
      settings ??
      (InMemorySettingsProvider()..values['defaultFilterDays'] = -1);
  final n = notifications ?? RecordingNotificationsProvider();
  await tester.pumpWidget(
    MultiBlocProvider(
      // a new key per test, so no state is kept from the previous app
      key: UniqueKey(),
      providers: [
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc(s)),
        BlocProvider<LocaleBloc>(create: (_) => LocaleBloc(s)),
        BlocProvider<SettingsBloc>(create: (_) => SettingsBloc(s, d)),
        BlocProvider<TimersBloc>(create: (_) => TimersBloc(d, s, n)),
        BlocProvider<ProjectsBloc>(create: (_) => ProjectsBloc(d)),
        BlocProvider<NotificationsBloc>(create: (_) => NotificationsBloc(n)),
      ],
      // lets screenshots capture the whole app (see test/screenshots)
      child: RepaintBoundary(
        key: appBoundaryKey,
        child: app.TimeCopApp(settings: s),
      ),
    ),
  );
  final testApp = TestApp(tester, d, s, n);
  await testApp.settle();
  return testApp;
}

bool _fontsLoaded = false;

/// Loads the fonts listed in the app's font manifest (Public Sans, Font
/// Awesome, Material Icons, …). Without this, text in tests is drawn as
/// placeholder boxes, which is fine for behaviour but not for golden images.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_fontsLoaded) return;
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}
