# iOS Zebra Print Starter (PNR -> Token API -> ZPL API -> Print)

This starter gives you production-style core code for:

1. Reading a PNR (from scanner or manual entry).
2. Calling an auth API to get a token.
3. Calling a second API with the token + PNR to get ZPL.
4. Sending ZPL to a Zebra printer over Bluetooth (MFi).
5. Showing local success/failure notifications.

## What is included

- Dynamic runtime API config loaded from JSON.
- `AuthService` for token retrieval.
- `ZplService` for PNR-to-ZPL call.
- `PrintCoordinator` orchestration.
- `ZebraPrinterClient` protocol + starter implementation hook.
- Local notification service.
- Global custom font theme helper (`AppCore/UI/AppTheme.swift`).

## Folder structure

- `Config/runtime-config.sample.json`: runtime API settings template.
- `Config/InfoPlist-keys.md`: required iOS plist keys.
- `AppCore/`: Swift core modules to include in your Xcode app target.

## Integrating into Xcode

1. Create a native iOS app in Xcode (Swift, UIKit or SwiftUI).
2. Copy files from `AppCore/` into your app target.
3. Add `runtime-config.json` to app bundle (rename from sample).
4. Add required keys from `Config/InfoPlist-keys.md` to `Info.plist`.
5. Add Zebra SDK XCFramework from:
   - `../zebra-linkos-mpsdk-ios-v1.6.1158/Link-OS_SDK/iOS/v1.6.1158/lib/xcframework/ZSDK_API.xcframework`
6. Implement scanner/manual PNR input and call `PrintCoordinator.processPNR(...)`.

## API contract expected

### Token API response

```json
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### ZPL API request (example)

```json
{
  "pnr": "ABC123",
  "stationCode": "AUH",
  "deviceId": "device-001"
}
```

### ZPL API response (example)

```json
{
  "jobId": "job-1001",
  "zpl": "^XA^FO50,50^ADN,36,20^FDHELLO^FS^XZ"
}
```

## Notes

- iOS background execution is best-effort. For high reliability, trigger print while app is foreground when possible.
- For background-triggered workflow, use APNs silent push and a queued job model on backend.
- For custom font setup, follow `Config/Fonts.md`.
