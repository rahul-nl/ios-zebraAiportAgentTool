# Vendor SDKs

Place third-party binary dependencies here.

For Zebra Link-OS:

1. Download/extract Zebra Link-OS iOS SDK.
2. Run:

```bash
./scripts/link_zebra_sdk.sh /absolute/path/to/ZSDK_API.xcframework
```

This creates a symlink:

- `Vendor/ZSDK_API.xcframework`

The Xcode project wiring expects this path.
