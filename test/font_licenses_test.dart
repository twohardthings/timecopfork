import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timecop/fontlicenses.dart';

// Regression test: the Public Sans OFL license pointed at a file that does
// not exist (fonts/LICENSE-PublicSans.txt instead of fonts/OFL-PublicSans.txt),
// so the Licenses page showed 'Unable to load asset'.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all bundled font licenses load', () async {
    final List<LicenseEntry> licenses = await getFontLicenses().toList();
    expect(licenses, hasLength(2));
    for (final license in licenses) {
      final text =
          license.paragraphs.map((LicenseParagraph p) => p.text).join('\n');
      expect(text, isNotEmpty, reason: license.packages.join(', '));
    }
  });
}
