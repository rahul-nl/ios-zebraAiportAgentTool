# Handoff Context (Windows -> Mac)

Use this file to continue the same work on Mac.

## Repository

- GitHub: https://github.com/rahul-nl/ios-zebraAiportAgentTool
- Branch: main
- Latest purpose: iOS native starter for PNR -> token API -> ZPL API -> Zebra Bluetooth print with custom font support

## What Is Already Implemented

- Dynamic runtime API config template.
- Token API client.
- ZPL API client using Bearer token.
- Orchestration flow: PNR -> token -> ZPL -> print -> notification.
- Runtime endpoint override support via UserDefaults.
- Zebra print implementation updated to use `MfiBtPrinterConnection` when `ZSDK_API` is linked.
- Graceful runtime error if Zebra SDK is not linked yet.
- Global app typography helper for custom fonts (`AppCore/UI/AppTheme.swift`).
- Custom font setup documentation (`Config/Fonts.md`).

## Current Project Structure

- AppCore/
  - API/
    - AuthService.swift
    - HTTPClient.swift
    - RuntimeConfigStore.swift
    - ZplService.swift
  - Notifications/
    - NotificationService.swift
  - UI/
    - AppTheme.swift
  - Zebra/
    - PrinterClient.swift
    - ZebraSdkImplementationGuide.md
  - ExampleUsage.swift
  - Models.swift
  - PrintCoordinator.swift
- Config/
  - Fonts.md
  - InfoPlist-keys.md
  - runtime-config.sample.json
- Resources/
  - Fonts/
    - README.md

## Important Notes

- This is a core starter, not a generated Xcode project yet.
- Create/open the iOS app project on Mac in Xcode.
- Copy AppCore and Config files into Xcode target.
- Add Zebra XCFramework from local SDK package.
- Add custom font files to Xcode target and register them in Info.plist.

## Zebra SDK Path (from your downloaded SDK)

- zebra-linkos-mpsdk-ios-v1.6.1158/Link-OS_SDK/iOS/v1.6.1158/lib/xcframework/ZSDK_API.xcframework

## Next Tasks On Mac

1. Create new iOS App in Xcode (Swift).
2. Add files from AppCore and Config into app target.
3. Add runtime-config.json (copy of sample) to app bundle.
4. Add required plist keys from Config/InfoPlist-keys.md.
5. Add `UIAppFonts` key and font entry (`EtihadAltis-Text.ttf`) as documented in Config/Fonts.md.
6. Link ZSDK_API.xcframework.
7. Verify Zebra SDK module import resolves in build (`canImport(ZSDK_API)` path in AppCore/Zebra/PrinterClient.swift).
8. Verify and update `AppTheme.primaryFontName` in AppCore/UI/AppTheme.swift using startup logs.
9. In app startup, call `AppTheme.bootstrap()` and `AppTheme.validateFontRegistration()` once.
10. Build a simple UI: scanner/manual PNR input + printer serial + print button/device selector.
11. Test flow: PNR -> token API -> ZPL API -> Zebra print -> local notification.

## Quick Verify Checklist On Mac

1. API calls succeed: token endpoint then ZPL endpoint with Bearer token.
2. ZPL string returned is non-empty.
3. `MfiBtPrinterConnection.open()` returns true for selected printer serial.
4. `write(data, error:)` returns without NSError.
5. Local notification shows success/failure.
6. Custom font renders in at least one visible title and body text.

## Suggested Prompt To Resume On Mac

Paste this to start the next chat:

"Continue from HANDOFF_CHAT_CONTEXT.md in this repo. Build the Xcode project wiring for AppCore, integrate ZSDK_API.xcframework, verify PrinterClient.swift Zebra Bluetooth printing on device, configure EtihadAltis custom font globally, and add a minimal SwiftUI screen with PNR input, printer selection, and print action."
