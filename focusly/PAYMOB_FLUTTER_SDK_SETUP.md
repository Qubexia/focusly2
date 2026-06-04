# Paymob Flutter SDK setup

This app now uses the Paymob Flutter SDK flow instead of opening the hosted checkout page in a browser.

## What changed

- Flutter now calls `Paymob.pay(publicKey, clientSecret, ...)`.
- The backend returns `publicKey`, `clientSecret`, and `canUseNativeSdk`.
- If the backend falls back to a legacy payment token, the app now stops and shows a clear error instead of opening a web page.

## Backend requirement

The Flutter SDK only works when Paymob returns a `client_secret` from the Intention API.

Use an **Online Card (MIGS)** integration for `PAYMOB_INTEGRATION_ID`.

If the backend is still using:
- VPC
- standalone
- iframe-only
- wallet-only legacy integrations

then the app will reject the flow because those paths are web/legacy and not suitable for the native SDK.

## Flutter dependency

Run:

```bash
flutter pub get
```

## Android native SDK

Download the Paymob Android SDK version required by the Flutter plugin and place the `.aar` file at:

```text
android/libs/com/paymob/sdk/Paymob-SDK/1.8.1/Paymob-SDK-1.8.1.aar
```

The Gradle repository and data binding setup are already prepared in this repo.

## iOS native SDK

Download `PaymobSDK.xcframework` and place it at:

```text
ios/Frameworks/PaymobSDK.xcframework
```

Then in Xcode:

1. Open `ios/Runner.xcworkspace`
2. Select Runner target
3. Add `ios/Frameworks/PaymobSDK.xcframework`
4. Set it to `Embed & Sign`

## Paymob dashboard settings

The Paymob Flutter package documentation says the response callback should be:

```text
https://accept.paymob.com/api/acceptance/post_pay
```

Keep your server webhook setup aligned with your current backend subscription flow, and make sure the integration you use is the native-SDK-compatible Online Card integration.
