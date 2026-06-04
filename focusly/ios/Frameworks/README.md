Place the Paymob iOS native SDK here before building.

Expected framework from the Paymob Flutter plugin documentation:

`ios/Frameworks/PaymobSDK.xcframework`

After copying it:
- Open `ios/Runner.xcworkspace` in Xcode
- Add `PaymobSDK.xcframework` to the Runner target
- Set it to `Embed & Sign`

Source:
- Paymob Flutter package on pub.dev
- Paymob Flutter SDK docs: https://developers.paymob.com/paymob-docs/developers/mobile-sdks/flutter-sdk
