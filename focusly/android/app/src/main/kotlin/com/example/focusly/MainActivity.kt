package com.example.focusly

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val dndChannel = "focusly/dnd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, dndChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPermissionGranted" -> result.success(isPermissionGranted())
                    "openPermissionSettings" -> {
                        openPermissionSettings()
                        result.success(null)
                    }
                    "setDnd" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        result.success(setDnd(enable))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    // Granting Do-Not-Disturb access is a one-time user action in system settings.
    private fun isPermissionGranted(): Boolean =
        notificationManager().isNotificationPolicyAccessGranted

    private fun openPermissionSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    // Returns false when we lack the policy-access permission so the caller can
    // fall back to leaving notifications untouched.
    private fun setDnd(enable: Boolean): Boolean {
        val manager = notificationManager()
        if (!manager.isNotificationPolicyAccessGranted) return false
        val filter = if (enable) {
            NotificationManager.INTERRUPTION_FILTER_NONE
        } else {
            NotificationManager.INTERRUPTION_FILTER_ALL
        }
        manager.setInterruptionFilter(filter)
        return true
    }
}
