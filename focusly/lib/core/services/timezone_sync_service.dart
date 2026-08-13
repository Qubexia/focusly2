import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../features/profile/data/datasources/profile_remote_datasource.dart';

/// Reports the device's IANA timezone (e.g. `Africa/Cairo`) to the backend.
///
/// The server decides which calendar day a session, a streak or a completed
/// task belongs to. Without this it falls back to UTC, and everything studied
/// after midnight local time gets filed under the previous day.
class TimezoneSyncService {
  TimezoneSyncService._();

  static final TimezoneSyncService instance = TimezoneSyncService._();

  final ProfileRemoteDataSource _dataSource = ProfileRemoteDataSource();

  String? _lastSyncedTimezone;
  bool _inFlight = false;

  /// Cheap to call on every login/resume: it only hits the API when the
  /// timezone actually changed since the last successful sync.
  Future<void> syncIfNeeded() async {
    if (_inFlight) return;
    _inFlight = true;

    try {
      final timezone = await _resolveTimezone();
      if (timezone == null || timezone == _lastSyncedTimezone) return;

      await _dataSource.updateSettings(timezone: timezone);
      _lastSyncedTimezone = timezone;
      debugPrint('[TimezoneSync] reported $timezone');
    } catch (e) {
      // A failed sync just means the server keeps the previous value; the next
      // login or resume tries again.
      debugPrint('[TimezoneSync] failed: $e');
    } finally {
      _inFlight = false;
    }
  }

  /// Forgets the cached value so the next sync always calls the API.
  void reset() => _lastSyncedTimezone = null;

  Future<String?> _resolveTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final identifier = info.identifier;
      return identifier.isEmpty ? null : identifier;
    } catch (_) {
      return null;
    }
  }
}
