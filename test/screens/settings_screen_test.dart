import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/models/theme_type.dart';
import 'package:timecop/screens/settings/SettingsScreen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  Future<TestApp> openSettings(
    WidgetTester tester, {
    InMemorySettingsProvider? settings,
  }) async {
    final app = await pumpApp(
      tester,
      // the app's real defaults
      settings: settings ?? InMemorySettingsProvider(),
    );
    await app.push(SettingsScreen());
    expect(tester.takeException(), isNull);
    return app;
  }

  Finder switchOf(String title) => find.descendant(
    of: find.widgetWithText(SwitchListTile, title),
    matching: find.byType(Switch),
  );

  // title, settings key, default
  const switches = <(String, String, bool)>[
    ('Group Similar Timers Per Day', 'groupTimers', true),
    ('Show Project Names', 'showProjectNames', false),
    ('Collapse Days', 'collapseDays', false),
    ('Autocomplete Descriptions', 'autocompleteDescription', true),
    (
      'Default Filter Start Date to Monday',
      'defaultFilterStartDateToMonday',
      false,
    ),
    ('Only Allow One Running Timer at a Time', 'oneTimerAtATime', false),
    (
      'Show Running Timer Notifications',
      'showRunningTimersAsNotifications',
      false,
    ),
    (
      'Remind to Start a Timer when None are Running',
      'nagAboutMissingTimer',
      false,
    ),
  ];

  for (final (title, key, initial) in switches) {
    testWidgets('"$title" can be switched and is stored', (tester) async {
      final app = await openSettings(tester);
      final settings = app.settings as InMemorySettingsProvider;
      await tester.ensureVisible(switchOf(title));
      expect(tester.widget<Switch>(switchOf(title)).value, initial);

      await tester.tap(switchOf(title));
      await app.settle();
      expect(tester.takeException(), isNull);
      expect(tester.widget<Switch>(switchOf(title)).value, !initial);
      expect(settings.values[key], !initial);

      await tester.tap(switchOf(title));
      await app.settle();
      expect(tester.widget<Switch>(switchOf(title)).value, initial);
      expect(settings.values[key], initial);
    });
  }

  testWidgets('stored settings are shown', (tester) async {
    await openSettings(
      tester,
      settings: InMemorySettingsProvider()
        ..values.addAll({'groupTimers': false, 'collapseDays': true}),
    );
    expect(
      tester.widget<Switch>(switchOf('Group Similar Timers Per Day')).value,
      isFalse,
    );
    expect(tester.widget<Switch>(switchOf('Collapse Days')).value, isTrue);
  });

  testWidgets('changes the theme', (tester) async {
    final app = await openSettings(tester);
    expect(Theme.of(app.context).brightness, Brightness.light);
    await tester.tap(find.byKey(const Key('themeOption')));
    await app.settle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('themeDark')));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(app.theme.state.theme, ThemeType.dark);
    expect((app.settings as InMemorySettingsProvider).theme, ThemeType.dark);
    expect(Theme.of(app.context).brightness, Brightness.dark);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('closing the theme list keeps the theme', (tester) async {
    final app = await openSettings(tester);
    await tester.tap(find.byKey(const Key('themeOption')));
    await app.settle();
    await tester.tapAt(const Offset(200, 20));
    await app.settle();
    expect(find.byKey(const Key('themeDark')), findsNothing);
    expect(app.theme.state.theme, ThemeType.light);
  });

  testWidgets('every theme can be chosen', (tester) async {
    final app = await openSettings(tester);
    const themes = {
      'themeAuto': ThemeType.auto,
      'themeDark': ThemeType.dark,
      'themeBlack': ThemeType.black,
      'themeAutoMaterialYou': ThemeType.autoMaterialYou,
      'themeLightMaterialYou': ThemeType.lightMaterialYou,
      'themeDarkMaterialYou': ThemeType.darkMaterialYou,
      'themeLight': ThemeType.light,
    };
    for (final entry in themes.entries) {
      await tester.tap(find.byKey(const Key('themeOption')));
      await app.settle();
      await tester.tap(find.byKey(Key(entry.key)));
      await app.settle();
      expect(tester.takeException(), isNull, reason: entry.key);
      expect(app.theme.state.theme, entry.value);
    }
  });

  /// The subtitle of the Language row.
  Finder languageSubtitle(String text) => find.descendant(
    of: find.byWidgetPredicate(
      (w) =>
          w is ListTile &&
          w.subtitle is Text &&
          (w.subtitle as Text).data == text,
    ),
    matching: find.text(text),
  );

  testWidgets('changes the language', (tester) async {
    final app = await openSettings(tester);
    expect(languageSubtitle('Automatic'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await app.settle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Deutsch'));
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(app.locale.state.locale, const Locale('de'));
    expect(
      (app.settings as InMemorySettingsProvider).locale,
      const Locale('de'),
    );
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Sprache'), findsOneWidget);
    // the row names the chosen language
    expect(languageSubtitle('Deutsch'), findsOneWidget);

    // back to automatic
    await tester.tap(find.text('Sprache'));
    await app.settle();
    await tester.tap(find.text('Automatisch').last);
    await app.settle();
    expect(app.locale.state.locale, isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(languageSubtitle('Automatic'), findsOneWidget);
  });

  testWidgets('the Language row names a stored language', (tester) async {
    await openSettings(
      tester,
      settings: InMemorySettingsProvider(locale: const Locale('zh', 'TW')),
    );
    expect(languageSubtitle('中文（繁體）'), findsOneWidget);
  });

  testWidgets('closing the language list keeps the language', (tester) async {
    final app = await openSettings(
      tester,
      settings: InMemorySettingsProvider(locale: const Locale('de')),
    );
    await tester.tap(find.text('Sprache'));
    await app.settle();
    await tester.tapAt(const Offset(200, 20));
    await app.settle();
    expect(find.byType(RadioListTile<Locale?>), findsNothing);
    expect(languageSubtitle('Deutsch'), findsOneWidget);
    expect(app.locale.state.locale, const Locale('de'));
    expect(find.text('Einstellungen'), findsOneWidget);
  });

  testWidgets('sets and removes the default filter period', (tester) async {
    final app = await openSettings(tester);
    final settings = app.settings as InMemorySettingsProvider;
    Finder tile() =>
        find.widgetWithText(ListTile, 'Default Filter Period (Days)');
    expect(
      find.descendant(of: tile(), matching: find.text('30')),
      findsOneWidget,
    );

    // remove: no default period
    await tester.tap(find.byTooltip('Remove'));
    await app.settle();
    expect(settings.values['defaultFilterDays'], -1);
    expect(
      find.descendant(of: tile(), matching: find.text('--')),
      findsOneWidget,
    );
    expect(find.byTooltip('Remove'), findsNothing);

    // the picker starts at 30 days again
    await tester.tap(tile());
    await app.settle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await app.settle();
    expect(settings.values['defaultFilterDays'], -1);

    await tester.tap(tile());
    await app.settle();
    await tester.tap(find.text('OK'));
    await app.settle();
    expect(settings.values['defaultFilterDays'], 30);
    expect(app.settingsBloc.state.defaultFilterDays, 30);
  });

  testWidgets('works in a right-to-left language', (tester) async {
    final app = await openSettings(
      tester,
      settings: InMemorySettingsProvider(locale: const Locale('ar')),
    );
    expect(Directionality.of(app.context), TextDirection.rtl);
    Navigator.of(app.context).pop();
    await app.settle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsScreen), findsNothing);
  });
}
