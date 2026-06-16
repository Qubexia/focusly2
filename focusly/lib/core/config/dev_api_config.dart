/// Local development API settings for physical devices.
///
/// On a real phone, `127.0.0.1` points to the phone — not your PC.
/// Set [physicalDeviceBaseUrl] to your computer's LAN IP (`ipconfig` on Windows).
///
/// Alternative (Android USB): leave empty and run
/// `adb reverse tcp:5000 tcp:5000`, then set [useOnMobileInDebug] to false.
class DevApiConfig {
  DevApiConfig._();

  /// Must match PORT in focaly-backend/.env (default 5000).
  static const String physicalDeviceBaseUrl = 'http://192.168.1.3:5000';

  /// Set false when using Android emulator (10.0.2.2) or adb reverse.
  static const bool useOnMobileInDebug = true;
}
