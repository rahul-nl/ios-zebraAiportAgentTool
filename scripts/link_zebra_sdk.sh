#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor"
TARGET_LINK="$VENDOR_DIR/ZSDK_API.xcframework"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/to/ZSDK_API.xcframework"
  exit 1
fi

SDK_PATH="$1"

if [[ ! -d "$SDK_PATH" ]]; then
  echo "Error: path does not exist: $SDK_PATH"
  exit 1
fi

mkdir -p "$VENDOR_DIR"

if [[ -e "$TARGET_LINK" || -L "$TARGET_LINK" ]]; then
  rm -rf "$TARGET_LINK"
fi

ln -s "$SDK_PATH" "$TARGET_LINK"

echo "Linked Zebra SDK: $TARGET_LINK -> $SDK_PATH"

if command -v xcodegen >/dev/null 2>&1; then
  "$ROOT_DIR/scripts/bootstrap_xcode_project.sh"
else
  echo "xcodegen not found; install it and run scripts/bootstrap_xcode_project.sh"
fi
