# Required Info.plist Keys

Add these keys to your iOS app `Info.plist`.

## Bluetooth printer via External Accessory (Zebra MFi)

```xml
<key>UIBackgroundModes</key>
<array>
  <string>external-accessory</string>
</array>

<key>UISupportedExternalAccessoryProtocols</key>
<array>
  <string>com.zebra.rawport</string>
</array>
```

## Network discovery/API calls (if needed)

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app scans local network resources to discover printers and services.</string>
```

## Camera access (if scanning barcode using camera)

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses camera to scan boarding passes.</string>
```

## Notifications (for print status)

No static plist key required for local notifications, but request permission at runtime.
