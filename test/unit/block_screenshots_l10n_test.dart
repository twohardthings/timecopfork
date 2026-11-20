import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/l10n.dart';

// "Block Screenshots" is translated in every language in l10n/.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final languages = Directory('l10n')
      .listSync()
      .map((f) => f.uri.pathSegments.last)
      .where((name) => name.endsWith('.flt'))
      .map((name) => name.substring(0, name.length - 4))
      .toList()
    ..sort();

  test('every language file is checked', () {
    expect(languages, contains('en'));
    expect(languages.length, greaterThan(1));
  });

  for (final language in languages) {
    test('Block Screenshots in $language', () async {
      final parts = language.split('-');
      final locale = Locale(parts[0], parts.length > 1 ? parts[1] : null);
      final l10n = await L10N.load(locale);
      expect(l10n.tr.blockScreenshots, isNot('blockScreenshots'));
      expect(l10n.tr.blockScreenshots, isNotEmpty);
      expect(
        l10n.tr.blockScreenshotsDescription,
        isNot('blockScreenshotsDescription'),
      );
      if (language == 'en') {
        expect(l10n.tr.blockScreenshots, 'Block Screenshots');
      }
    });
  }
}
