import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the device-wide Do-Not-Disturb (interruption) filter so a premium
/// user's focus session can silence every notification on the phone.
///
/// Android only: iOS exposes no public API to toggle the system Do-Not-Disturb
/// / Focus mode, so every method is a safe no-op there.
class DndService {
  DndService._internal();
  static final DndService _instance = DndService._internal();
  factory DndService() => _instance;

  static const MethodChannel _channel = MethodChannel('focusly/dnd');

  // Remembers that we already nudged the user to the system settings, so we
  // never hijack the screen on every session start.
  static const String _promptedKey = 'dnd_permission_prompted';

  // Tracks that *we* turned silence on, so disabling only ever reverses our own
  // change and never overrides a Do-Not-Disturb the user set manually.
  static const String _engagedKey = 'dnd_engaged_by_focus';

  bool get _supported => Platform.isAndroid;

  Future<bool> _isPermissionGranted() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Silence the whole device for the duration of a focus session. If the
  /// system permission has not been granted yet, opens the settings screen once
  /// so the user can enable it; the session continues silenced or not either way.
  Future<void> enableFocusSilence() async {
    if (!_supported) return;
    try {
      if (await _isPermissionGranted()) {
        final ok =
            await _channel.invokeMethod<bool>('setDnd', {'enable': true}) ??
                false;
        if (ok) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_engagedKey, true);
        }
        return;
      }

      // Permission missing: guide the user to grant it, but only the first time.
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_promptedKey) ?? false) return;
      await prefs.setBool(_promptedKey, true);
      await _channel.invokeMethod('openPermissionSettings');
    } on PlatformException {
      // Best-effort: never let a DND failure break the focus session.
    }
  }

  /// Restore normal notifications, but only if this service is what silenced the
  /// device. Safe to call for non-premium users or when permission was denied.
  Future<void> disableFocusSilence() async {
    if (!_supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_engagedKey) ?? false)) return;
      if (await _isPermissionGranted()) {
        await _channel.invokeMethod('setDnd', {'enable': false});
      }
      await prefs.setBool(_engagedKey, false);
    } on PlatformException {
      // Best-effort.
    }
  }
}
