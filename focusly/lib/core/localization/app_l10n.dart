import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Context-free access to translations for non-widget layers (cubits, blocs,
/// services) that emit user-facing text but have no [BuildContext].
///
/// Kept in sync with the locale Flutter actually resolved for the UI — the
/// root [MaterialApp.router] `builder` calls [update] on every rebuild, so
/// `AppL10n.current` always matches what the user sees on screen.
class AppL10n {
  AppL10n._();

  static AppLocalizations _current =
      lookupAppLocalizations(const Locale('en'));

  /// The translations for the currently displayed locale.
  static AppLocalizations get current => _current;

  /// Called from the widget tree with the resolved locale.
  static void update(Locale locale) {
    _current = lookupAppLocalizations(_resolveSupported(locale));
  }

  static Locale _resolveSupported(Locale locale) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
    return const Locale('en');
  }
}
