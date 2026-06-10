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

## Native SDK install (required once)

Paymob hosts the native binaries on SharePoint (login required). Run the helper script from the `Zakerly/` folder:

```powershell
.\scripts\setup-paymob-native.ps1 -OpenDownloads
```

Then paste the extracted folder paths when prompted, or pass them directly:

```powershell
.\scripts\setup-paymob-native.ps1 `
  -AndroidSource "$env:USERPROFILE\Downloads\PaymobAndroidSDK1.8.1" `
  -IosSource "$env:USERPROFILE\Downloads\PaymobSDK 1.3.3"
```

Manual download links (same as [paymob pub.dev](https://pub.dev/packages/paymob)):

- Android 1.8.1: https://paymob-my.sharepoint.com/:f:/p/ahmedsobhy/EjQrdOdzUzhIqlQmcsE9Hg0BOVjJYOu2BMGRClGVEa9dJA?e=hfFnnI
- iOS 1.3.3: https://paymob-my.sharepoint.com/:f:/p/mahmoudyoussef/El9q1ULaxcBFkQurwvXkZQEBY9S-6dwhWL9xXQgjEnGPBQ?e=0sKgCf

## Paymob dashboard settings

The Paymob Flutter package documentation says the response callback should be:

```text
https://accept.paymob.com/api/acceptance/post_pay
```

Keep your server webhook setup aligned with your current backend subscription flow, and make sure the integration you use is the native-SDK-compatible Online Card integration.
