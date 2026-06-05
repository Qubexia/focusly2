Place the Paymob iOS native SDK here before building.

Run the setup script (opens download links and installs files):

```powershell
.\scripts\setup-paymob-native.ps1 -OpenDownloads
```

Expected framework from the Paymob Flutter plugin documentation:

`ios/Frameworks/PaymobSDK.xcframework`

The Xcode project is already configured to link and embed this framework (Embed & Sign).

Source:
- Paymob Flutter package on pub.dev
- Paymob Flutter SDK docs: https://developers.paymob.com/paymob-docs/developers/mobile-sdks/flutter-sdk
