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

  /// Silence the whole device for the duration of a focus session.
  /// Returns true when DND was enabled; false when permission is missing or
  /// the platform call failed.
  Future<bool> enableFocusSilence() async {
    if (!_supported) return false;
    try {
      if (await _isPermissionGranted()) {
        final ok =
            await _channel.invokeMethod<bool>('setDnd', {'enable': true}) ??
                false;
        if (ok) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_engagedKey, true);
        }
        return ok;
      }

      // Permission missing: open system settings so the user can grant access.
      await _channel.invokeMethod('openPermissionSettings');
      return false;
    } on PlatformException {
      return false;
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
