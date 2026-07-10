/// OAuth configuration for social sign-in.
///
/// Set [googleServerClientId] via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
/// at build time. It must match `GOOGLE_CLIENT_ID` on the backend (Firebase
/// Web client ID from the Google Cloud console).
class AuthConfig {
  AuthConfig._();

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
