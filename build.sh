#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${1:-$ROOT/dist/Nova OS.app}"
PACKAGE="${OUTPUT%.app} Installer.pkg"
BUILD_DIR="$ROOT/build"
CONTENTS="$OUTPUT/Contents"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
CACHE_ARGS=(
  -module-cache-path "$BUILD_DIR/SwiftModuleCache"
  -Xcc "-fmodules-cache-path=$BUILD_DIR/ClangModuleCache"
  -clang-scanner-module-cache-path "$BUILD_DIR/ClangScannerCache"
)

rm -rf "$BUILD_DIR" "$OUTPUT" "$PACKAGE"
mkdir -p "$BUILD_DIR" "$CONTENTS/MacOS"

swiftc "${CACHE_ARGS[@]}" -parse-as-library -sdk "$SDK" -target arm64-apple-macos13.0 \
  "$ROOT/NovaOSApp.swift" -framework AppKit -framework WebKit \
  -o "$BUILD_DIR/NovaOS-arm64"
swiftc "${CACHE_ARGS[@]}" -parse-as-library -sdk "$SDK" -target x86_64-apple-macos13.0 \
  "$ROOT/NovaOSApp.swift" -framework AppKit -framework WebKit \
  -o "$BUILD_DIR/NovaOS-x86_64"
lipo -create "$BUILD_DIR/NovaOS-arm64" "$BUILD_DIR/NovaOS-x86_64" \
  -output "$CONTENTS/MacOS/NovaOS"

cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"

chmod +x "$CONTENTS/MacOS/NovaOS"
codesign --force --deep --sign - "$OUTPUT"
plutil -lint "$CONTENTS/Info.plist"
codesign --verify --deep --strict "$OUTPUT"
lipo -info "$CONTENTS/MacOS/NovaOS"
pkgbuild --component "$OUTPUT" --install-location /Applications \
  --identifier com.novaos.desktop --version 1.0 "$PACKAGE"

echo "Built: $OUTPUT"
echo "Installer: $PACKAGE"
