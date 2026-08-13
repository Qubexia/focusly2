/// OAuth configuration for social sign-in.
///
/// Default is the Firebase/Google **Web** client ID (same value as backend
/// `GOOGLE_CLIENT_ID`). Override at build time with:
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
class AuthConfig {
  AuthConfig._();

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '264301190550-asllhnma6e86477cm9tckti0h03ln223.apps.googleusercontent.com',
  );
}
