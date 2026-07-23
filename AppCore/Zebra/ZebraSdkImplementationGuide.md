# ZebraPrinterClient Implementation Guide

In `ZebraPrinterClient.printZpl`, replace the placeholder throw with real Zebra SDK code.

## SDK location

Use this XCFramework from your workspace:

- `zebra-linkos-mpsdk-ios-v1.6.1158/Link-OS_SDK/iOS/v1.6.1158/lib/xcframework/ZSDK_API.xcframework`

## Suggested Objective-C bridge approach

Because Zebra headers are Objective-C, many teams use a tiny Objective-C wrapper and call it from Swift.

### Wrapper responsibilities

1. Create `MfiBtPrinterConnection` with printer serial.
2. Call `open`.
3. Convert ZPL string to UTF-8 bytes.
4. Call `write:error:`.
5. Call `close` in `finally` style.

## Swift pseudo-flow

```swift
let connection = MfiBtPrinterConnection(serialNumber: printerSerial)
let opened = connection.open()
if !opened { throw ... }
defer { connection.close() }

let data = zpl.data(using: .utf8)!
var error: NSError?
_ = connection.write(data, error: &error)
if let error = error { throw ... }
```

## Required plist keys

See `Config/InfoPlist-keys.md`.
