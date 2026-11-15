import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/data_providers/data/data_provider.dart';
import 'package:timecop/data_providers/notifications/notifications_provider.dart';
import 'package:timecop/data_providers/settings/settings_provider.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/models/theme_type.dart';
import 'package:timecop/models/timer_entry.dart';

/// A [DataProvider] that keeps everything in memory and, unlike
/// `MockDataProvider`, really stores what is created, edited and deleted.
class InMemoryDataProvider extends DataProvider {
  final List<Project> projects = [];
  final List<TimerEntry> timers = [];
  int _nextProjectId = 1;
  int _nextTimerId = 1;

  @override
  Future<Project> createProject({
    required String name,
    Color? colour,
    bool? archived,
  }) async {
    final project = Project(
      id: _nextProjectId++,
      name: name,
      colour: colour ?? const Color(0xFF8E24AA),
      archived: archived ?? false,
    );
    projects.add(project);
    return project;
  }

  @override
  Future<List<Project>> listProjects() async =>
      [...projects]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<void> editProject(Project project) async {
    final i = projects.indexWhere((p) => p.id == project.id);
    if (i >= 0) projects[i] = project;
  }

  @override
  Future<void> deleteProject(Project project) async {
    projects.removeWhere((p) => p.id == project.id);
    // like the database's "on delete set null"
    for (var i = 0; i < timers.length; i++) {
      final t = timers[i];
      if (t.projectID == project.id) {
        timers[i] = TimerEntry(
          id: t.id,
          description: t.description,
          projectID: null,
          startTime: t.startTime,
          endTime: t.endTime,
          notes: t.notes,
        );
      }
    }
  }

  @override
  Future<TimerEntry> createTimer({
    String? description,
    int? projectID,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
  }) async {
    final timer = TimerEntry(
      id: _nextTimerId++,
      description: description,
      projectID: projectID,
      startTime: startTime ?? DateTime.now(),
      endTime: endTime,
      notes: notes,
    );
    timers.add(timer);
    return timer;
  }

  @override
  Future<List<TimerEntry>> listTimers() async =>
      [...timers]..sort((a, b) => a.startTime.compareTo(b.startTime));

  @override
  Future<void> editTimer(TimerEntry timer) async {
    final i = timers.indexWhere((t) => t.id == timer.id);
    if (i >= 0) timers[i] = timer;
  }

  @override
  Future<void> deleteTimer(TimerEntry timer) async {
    timers.removeWhere((t) => t.id == timer.id);
  }
}

/// A [SettingsProvider] that keeps everything in memory. Unset keys return
/// `null`, so the blocs fall back to the app's real defaults
/// (`MockSettingsProvider` answers `true` and `-1` instead).
class InMemorySettingsProvider extends SettingsProvider {
  final Map<String, Object?> values = {};
  ThemeType? theme;
  Locale? locale;

  InMemorySettingsProvider({this.theme = ThemeType.light, this.locale});

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool? value) async => values[key] = value;

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  Future<void> setInt(String key, int value) async => values[key] = value;

  @override
  ThemeType? getTheme() => theme;

  @override
  Future<void> setTheme(ThemeType? theme) async => this.theme = theme;

  @override
  Locale? getLocale() => locale;

  @override
  Future<void> setLocale(Locale? locale) async => this.locale = locale;
}

/// A [NotificationsProvider] that records what would have been shown
/// instead of calling the notifications plugin.
class RecordingNotificationsProvider extends NotificationsProvider {
  final List<String> shown = [];
  int removed = 0;

  RecordingNotificationsProvider() : super(FlutterLocalNotificationsPlugin());

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> displayRunningTimersNotification(
    String? title,
    String? body,
  ) async => shown.add('running: $title');

  @override
  Future<void> displayNoRunningTimersNotification(
    String? title,
    String? body,
  ) async => shown.add('none: $title');

  @override
  Future<void> removeAllNotifications() async => removed++;
}

/// A file that the app "saved" through the [RecordingFilePicker].
typedef SavedFile = ({String fileName, String mimeType, Uint8List bytes});

/// Replaces the platform's file dialogs: "save" calls are recorded instead of
/// opening a dialog. Install it with `FilePickerPlatform.instance = ...`.
class RecordingFilePicker extends FilePickerPlatform {
  final List<SavedFile> saved = [];

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    saved.add((fileName: fileName, mimeType: mimeType, bytes: bytes));
    return Uri.file('/tmp/$fileName');
  }
}

/// Sample data with fixed dates: two projects (one with a long name), an
/// archived project and a handful of stopped timers in March 2020.
Future<InMemoryDataProvider> sampleData({bool withRunningTimer = false}) async {
  final data = InMemoryDataProvider();
  final timecop = await data.createProject(
    name: 'Time Cop',
    colour: const Color(0xFF00ACC1),
  );
  final admin = await data.createProject(
    name: 'Administration',
    colour: const Color(0xFFD81B60),
  );
  await data.createProject(
    name: 'Old project',
    colour: const Color(0xFF7CB342),
    archived: true,
  );
  Future<void> add(
    String description,
    Project? project,
    int day,
    int startHour,
    int startMinute,
    int minutes, {
    String? notes,
  }) => data.createTimer(
    description: description,
    projectID: project?.id,
    startTime: DateTime(2020, 3, day, startHour, startMinute),
    endTime: DateTime(
      2020,
      3,
      day,
      startHour,
      startMinute,
    ).add(Duration(minutes: minutes)),
    notes: notes,
  );

  await add('UI Layout', timecop, 2, 8, 30, 150);
  await add('Administration', admin, 2, 14, 0, 60);
  await add('App development', timecop, 3, 9, 0, 240, notes: 'Pickers');
  await add('App development', timecop, 3, 14, 15, 45);
  await add('Mockups', timecop, 4, 10, 0, 90);
  await add('Coffee', null, 4, 15, 0, 15);
  if (withRunningTimer) {
    await data.createTimer(
      description: 'Writing tests',
      projectID: timecop.id,
      startTime: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  }
  return data;
}
