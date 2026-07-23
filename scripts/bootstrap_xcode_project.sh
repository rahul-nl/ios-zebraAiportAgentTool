#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SDK_FRAMEWORK="$ROOT_DIR/Vendor/ZSDK_API.xcframework"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found. Install with: brew install xcodegen"
  exit 1
fi

cd "$ROOT_DIR"
if [[ -d "$SDK_FRAMEWORK" ]]; then
  xcodegen generate --spec project.with-zebra.yml
  echo "Generated with Zebra SDK linkage (Vendor/ZSDK_API.xcframework)."
else
  xcodegen generate --spec project.yml
  echo "Generated without Zebra SDK linkage."
  echo "To enable Zebra printing, run scripts/link_zebra_sdk.sh with your SDK path and regenerate."
fi

echo "Generated: $ROOT_DIR/ZebraAirportAgentTool.xcodeproj"
