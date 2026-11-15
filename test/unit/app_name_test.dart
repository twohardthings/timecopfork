import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timecop/l10n.dart';

// The fork's name ("Time Cop Fork") with the "Fork" suffix translated in
// every supported language (see l10n/*.flt).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expected = <String, String>{
    'en': 'Time Cop Fork',
    'ar': 'شرطي الوقت المتفرع',
    'cs': 'Time Cop Fork',
    'da': 'Time Cop Fork',
    'de': 'Time Cop Fork',
    'es': 'Time Cop (bifurcación)',
    'fr': 'Time Cop Fork',
    'hi': 'समय कॉप फ़ोर्क',
    'id': 'Time Cop Fork',
    'it': 'Time Cop Fork',
    'ja': 'TimeCop フォーク',
    'ko': '타임 경찰 포크',
    'nb-NO': 'Time Cop Fork',
    'pt': 'Time Cop (bifurcação)',
    'ru': 'Time Cop Форк',
    'tr': 'Zaman Polisi Çatalı',
    'zh-CN': '时间警察复刻版',
    'zh-TW': '時間警察複刻版',
  };

  for (final entry in expected.entries) {
    test('appName in ${entry.key}', () async {
      final parts = entry.key.split('-');
      final locale = Locale(parts[0], parts.length > 1 ? parts[1] : null);
      final l10n = await L10N.load(locale);
      expect(l10n.tr.appName, entry.value);
    });
  }
}
