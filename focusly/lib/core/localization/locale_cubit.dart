import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's chosen [Locale]. A `null` state means "follow the device
/// language", which lets Flutter resolve against [supportedLocales].
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit() : super(null) {
    _restore();
  }

  static const _prefsKey = 'app_locale';

  /// Language codes the app ships translations for.
  static const supportedLanguageCodes = <String>['en', 'ar'];

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supportedLanguageCodes.contains(code)) {
      emit(Locale(code));
    }
  }

  /// Sets [locale], or pass `null` to follow the device language.
  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
    emit(locale);
  }
}
