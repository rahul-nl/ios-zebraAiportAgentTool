# Handoff Context (Windows -> Mac)

Use this file to continue the same work on Mac.

## Repository

- GitHub: https://github.com/rahul-nl/ios-zebraAiportAgentTool
- Branch: main
- Latest purpose: iOS native starter for PNR -> token API -> ZPL API -> Zebra Bluetooth print

## What Is Already Implemented

- Dynamic runtime API config template.
- Token API client.
- ZPL API client using Bearer token.
- Orchestration flow: PNR -> token -> ZPL -> print -> notification.
- Runtime endpoint override support via UserDefaults.
- Zebra print adapter boundary with implementation guide.

## Current Project Structure

- AppCore/
  - API/
    - AuthService.swift
    - HTTPClient.swift
    - RuntimeConfigStore.swift
    - ZplService.swift
  - Notifications/
    - NotificationService.swift
  - Zebra/
    - PrinterClient.swift
    - ZebraSdkImplementationGuide.md
  - ExampleUsage.swift
  - Models.swift
  - PrintCoordinator.swift
- Config/
  - InfoPlist-keys.md
  - runtime-config.sample.json

## Important Notes

- This is a core starter, not a generated Xcode project yet.
- Create/open the iOS app project on Mac in Xcode.
- Copy AppCore and Config files into Xcode target.
- Add Zebra XCFramework from local SDK package.

## Zebra SDK Path (from your downloaded SDK)

- zebra-linkos-mpsdk-ios-v1.6.1158/Link-OS_SDK/iOS/v1.6.1158/lib/xcframework/ZSDK_API.xcframework

## Next Tasks On Mac

1. Create new iOS App in Xcode (Swift).
2. Add files from AppCore and Config into app target.
3. Add runtime-config.json (copy of sample) to app bundle.
4. Add required plist keys from Config/InfoPlist-keys.md.
5. Link ZSDK_API.xcframework.
6. Implement real Zebra print in AppCore/Zebra/PrinterClient.swift using MfiBtPrinterConnection.
7. Build a simple UI: scanner/manual PNR input + printer serial + print button.
8. Test flow: PNR -> token API -> ZPL API -> Zebra print -> local notification.

## Suggested Prompt To Resume On Mac

Paste this to start the next chat:

"Continue from HANDOFF_CHAT_CONTEXT.md in this repo. Build the Xcode project wiring for AppCore, integrate ZSDK_API.xcframework, implement Zebra Bluetooth print in PrinterClient.swift, and add a minimal SwiftUI screen for PNR input + print action."
