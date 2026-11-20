import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Turns Android's FLAG_SECURE on or off for the app's window. It blocks
/// screenshots and screen recordings, and hides the app's content in the
/// list of recent apps. Does nothing on other platforms.
///
/// MainActivity also applies the stored setting before the first frame.
class SecureScreen {
  @visibleForTesting
  static const channel = MethodChannel('timecopfork/secure_screen');

  static Future<void> setEnabled(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await channel.invokeMethod<void>('setSecure', enabled);
    } on MissingPluginException {
      // No activity to change, e.g. in widget tests.
    } on PlatformException catch (e) {
      debugPrint('Could not change FLAG_SECURE: ${e.message}');
    }
  }
}
