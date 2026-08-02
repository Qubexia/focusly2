/// OAuth configuration for social sign-in.
///
/// Set [googleServerClientId] via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
/// at build time.
///
/// Example (Android):
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
/// Must match backend `GOOGLE_CLIENT_ID` (Firebase/Google Web client ID).
class AuthConfig {
  AuthConfig._();

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
