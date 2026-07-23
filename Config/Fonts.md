# Custom Font Setup (EtihadAltis-Text)

This project supports a single global custom font setup through `AppCore/UI/AppTheme.swift`.

## 1) Add font file to Xcode target

1. In Xcode, drag `EtihadAltis-Text.ttf` into your app project.
2. Select `Copy items if needed`.
3. Ensure your app target is checked.

## 2) Register font in Info.plist

Add this key:

```xml
<key>UIAppFonts</key>
<array>
    <string>EtihadAltis-Text.ttf</string>
</array>
```

## 3) Initialize theme at app startup

In your app entry point, call:

```swift
AppTheme.bootstrap()
AppTheme.validateFontRegistration()
```

You can remove `validateFontRegistration()` after confirming logs once.

## 4) Apply font in views

### SwiftUI

```swift
Text("Print Boarding Label")
    .appFont(.title)

Text("Enter PNR")
    .appFont(.body)
```

### UIKit

```swift
titleLabel.font = AppFont.uiFont(.title)
bodyLabel.font = AppFont.uiFont(.body)
```

## Notes

- The internal font name might differ from file name.
- If the font does not render, check startup logs from `validateFontRegistration()` and update `AppTheme.primaryFontName` accordingly.
