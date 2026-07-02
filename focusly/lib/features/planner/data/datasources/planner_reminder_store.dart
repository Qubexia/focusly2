import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the "minutes before due" reminder offset the user picked for each
/// planned item. The backend stores no reminder offset, so without this the
/// "before due" reminder could only be scheduled once at creation time and was
/// lost whenever the app was closed before it fired. Keeping it locally lets
/// the re-sync on every [loadDate] re-arm the reminder too, not just the DUE
/// alert.
class PlannerReminderStore {
  static const String _storageKey = 'planner_reminder_offsets';

  Future<Map<String, int>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Future<void> _writeAll(Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  /// Returns the saved offset in minutes, or null when the item has none.
  Future<int?> getOffset(String itemId) async {
    if (itemId.isEmpty) return null;
    final all = await _readAll();
    return all[itemId];
  }

  Future<void> setOffset(String itemId, int minutes) async {
    if (itemId.isEmpty) return;
    final all = await _readAll();
    all[itemId] = minutes;
    await _writeAll(all);
  }

  Future<void> remove(String itemId) async {
    if (itemId.isEmpty) return;
    final all = await _readAll();
    if (all.remove(itemId) != null) {
      await _writeAll(all);
    }
  }
}
