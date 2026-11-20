package ca.hamaluik.timecop

import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Apply "Block Screenshots" before anything is drawn, so neither the
        // first frame nor the recent apps thumbnail shows the app's content.
        // The shared_preferences plugin stores the setting in this file, with
        // a "flutter." prefix.
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        setSecure(prefs.getBoolean("flutter.blockScreenshots", false))
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "timecopfork/secure_screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    setSecure(call.arguments as? Boolean ?: false)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun setSecure(secure: Boolean) {
        if (secure) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
