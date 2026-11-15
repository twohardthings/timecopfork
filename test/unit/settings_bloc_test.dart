import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:timecop/blocs/locale/locale_bloc.dart';
import 'package:timecop/blocs/settings/bloc.dart';
import 'package:timecop/blocs/theme/theme_bloc.dart';
import 'package:timecop/models/theme_type.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemorySettingsProvider settings;
  late SettingsBloc bloc;

  Future<SettingsState> run(SettingsEvent event) {
    final next = bloc.stream.first;
    bloc.add(event);
    return next;
  }

  setUp(() {
    settings = InMemorySettingsProvider();
    bloc = SettingsBloc(settings, InMemoryDataProvider());
  });

  tearDown(() => bloc.close());

  test('nothing stored: loading keeps the defaults', () async {
    // LoadSettingsFromRepository emits a state equal to the initial one, which
    // the bloc doesn't publish again, so wait for the event to be handled.
    bloc.add(LoadSettingsFromRepository());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, SettingsState.initial());
    expect(bloc.state.groupTimers, isTrue);
    expect(bloc.state.defaultFilterDays, 30);
  });

  test('stored values are loaded', () async {
    settings.values.addAll({
      'groupTimers': false,
      'collapseDays': true,
      'oneTimerAtATime': true,
      'exportIncludeStartTime': true,
      'defaultFilterDays': 7,
    });
    final state = await run(LoadSettingsFromRepository());
    expect(state.groupTimers, isFalse);
    expect(state.collapseDays, isTrue);
    expect(state.oneTimerAtATime, isTrue);
    expect(state.exportIncludeStartTime, isTrue);
    expect(state.defaultFilterDays, 7);
    // untouched settings keep their defaults
    expect(state.autocompleteDescription, isTrue);
  });

  test('SetBoolValueEvent changes and stores only the given values', () async {
    final state = await run(
      const SetBoolValueEvent(groupTimers: false, showProjectNames: true),
    );
    expect(state.groupTimers, isFalse);
    expect(state.showProjectNames, isTrue);
    expect(state.collapseDays, SettingsState.initial().collapseDays);
    expect(settings.values, {'groupTimers': false, 'showProjectNames': true});
  });

  test(
    'turning on notifications remembers that permission was asked',
    () async {
      final state = await run(
        const SetBoolValueEvent(showRunningTimersAsNotifications: true),
      );
      expect(state.showRunningTimersAsNotifications, isTrue);
      expect(state.hasAskedNotificationPermissions, isTrue);
      expect(settings.values['hasAskedNotificationPermissions'], isTrue);
    },
  );

  test(
    'SetDefaultFilterDays stores the days; null turns the filter off',
    () async {
      var state = await run(const SetDefaultFilterDays(14));
      expect(state.defaultFilterDays, 14);
      expect(settings.values['defaultFilterDays'], 14);
      expect(bloc.getDefaultFilterDays(), 14);

      state = await run(const SetDefaultFilterDays(null));
      expect(state.defaultFilterDays, -1);
      expect(settings.values['defaultFilterDays'], -1);
      expect(bloc.getFilterStartDate(), isNull);
      expect(bloc.getDefaultFilterDays(), 30);
    },
  );

  test('getFilterStartDate goes back the default number of days', () async {
    await run(const SetDefaultFilterDays(7));
    final start = bloc.getFilterStartDate()!;
    final expected = DateTime.now().subtract(const Duration(days: 7));
    expect(start.difference(expected).inSeconds.abs(), lessThan(5));
  });

  test('getFilterStartDate can start at this week\'s Monday', () async {
    await run(const SetBoolValueEvent(defaultFilterStartDateToMonday: true));
    final start = bloc.getFilterStartDate()!;
    expect(start.weekday, DateTime.monday);
    expect(DateTime.now().difference(start).inDays, lessThan(7));
  });

  test('ThemeBloc loads and stores the theme', () async {
    settings.theme = ThemeType.dark;
    final theme = ThemeBloc(settings);
    addTearDown(theme.close);
    var next = theme.stream.first;
    theme.add(const LoadThemeEvent());
    expect((await next).theme, ThemeType.dark);

    next = theme.stream.first;
    theme.add(const ChangeThemeEvent(ThemeType.black));
    expect((await next).theme, ThemeType.black);
    expect(settings.theme, ThemeType.black);
  });

  test('LocaleBloc loads and stores the language', () async {
    settings.locale = const Locale('de');
    final locale = LocaleBloc(settings);
    addTearDown(locale.close);
    var next = locale.stream.first;
    locale.add(const LoadLocaleEvent());
    expect((await next).locale, const Locale('de'));

    next = locale.stream.first;
    locale.add(const ChangeLocaleEvent(Locale('es')));
    expect((await next).locale, const Locale('es'));
    expect(settings.locale, const Locale('es'));
  });
}
