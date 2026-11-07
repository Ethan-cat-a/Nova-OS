#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${1:-$ROOT/dist/Nova OS.app}"
PACKAGE="${OUTPUT%.app} Installer.pkg"
BUILD_DIR="$ROOT/build"
SPM_DIR="$BUILD_DIR/SwiftPM"
CONTENTS="$OUTPUT/Contents"
FRAMEWORKS="$CONTENTS/Frameworks"
ICONSET="$BUILD_DIR/AppIcon.iconset"
ICON_PNG="$BUILD_DIR/AppIcon-1024.png"
ICON_ICNS="$BUILD_DIR/AppIcon.icns"
KEY="$ROOT/.secrets/sparkle-ed25519.private"
UPDATES="$ROOT/updates"
APPCAST_URL_PREFIX="https://raw.githubusercontent.com/Ethan-cat-a/Nova-OS/main/updates/"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT/Info.plist")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$ROOT/Info.plist")"
UPDATER_ZIP="$UPDATES/Nova OS $VERSION-build$BUILD_NUMBER.zip"

export SWIFT_MODULE_CACHE_PATH="$BUILD_DIR/SwiftModuleCache"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/ClangModuleCache"

if [[ ! -f "$KEY" ]]; then
  echo "Missing local Sparkle signing key at $KEY" >&2
  exit 1
fi

rm -rf "$OUTPUT" "$PACKAGE" "$ICONSET" "$ICON_PNG" "$ICON_ICNS" "$UPDATER_ZIP"
mkdir -p "$BUILD_DIR" "$CONTENTS/MacOS" "$FRAMEWORKS" "$ICONSET" "$UPDATES"

swift package --disable-sandbox \
  --cache-path "$BUILD_DIR/SwiftPMCache" \
  --config-path "$BUILD_DIR/SwiftPMConfig" \
  --security-path "$BUILD_DIR/SwiftPMSecurity" \
  --scratch-path "$SPM_DIR" \
  --manifest-cache local resolve

swift build --disable-sandbox \
  --cache-path "$BUILD_DIR/SwiftPMCache" \
  --config-path "$BUILD_DIR/SwiftPMConfig" \
  --security-path "$BUILD_DIR/SwiftPMSecurity" \
  --scratch-path "$SPM_DIR" \
  --manifest-cache local -c release -debug-info-format none --triple arm64-apple-macosx13.0
cp "$SPM_DIR/out/Products/Release/NovaOS" "$BUILD_DIR/NovaOS-arm64"

swift build --disable-sandbox \
  --cache-path "$BUILD_DIR/SwiftPMCache" \
  --config-path "$BUILD_DIR/SwiftPMConfig" \
  --security-path "$BUILD_DIR/SwiftPMSecurity" \
  --scratch-path "$SPM_DIR" \
  --manifest-cache local -c release -debug-info-format none --triple x86_64-apple-macosx13.0
cp "$SPM_DIR/out/Products/Release/NovaOS" "$BUILD_DIR/NovaOS-x86_64"

ARM_BINARY="$BUILD_DIR/NovaOS-arm64"
INTEL_BINARY="$BUILD_DIR/NovaOS-x86_64"
if [[ ! -f "$ARM_BINARY" || ! -f "$INTEL_BINARY" ]]; then
  echo "SwiftPM did not produce both universal app binaries." >&2
  exit 1
fi
lipo -create "$ARM_BINARY" "$INTEL_BINARY" -output "$CONTENTS/MacOS/NovaOS"

FRAMEWORK_SOURCE="$SPM_DIR/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
ditto "$FRAMEWORK_SOURCE" "$FRAMEWORKS/Sparkle.framework"
if ! otool -l "$CONTENTS/MacOS/NovaOS" | grep -q '@executable_path/../Frameworks'; then
  install_name_tool -add_rpath '@executable_path/../Frameworks' "$CONTENTS/MacOS/NovaOS"
fi
cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"

swiftc -module-cache-path "$BUILD_DIR/SwiftModuleCache" \
  -Xcc "-fmodules-cache-path=$BUILD_DIR/ClangModuleCache" \
  "$ROOT/scripts/generate-icon.swift" -o "$BUILD_DIR/generate-icon"
"$BUILD_DIR/generate-icon" "$ROOT/assets/nova-icon-background.png" "$ICON_PNG"
cp "$ICON_PNG" "$ROOT/assets/nova-icon.png"

make_icon() {
  local size="$1"
  local filename="$2"
  sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET/$filename" >/dev/null
}
make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
make_icon 1024 icon_512x512@2x.png
python3 "$ROOT/scripts/make-icns.py" "$ICONSET" "$ICON_ICNS"
mkdir -p "$CONTENTS/Resources"
cp "$ICON_ICNS" "$CONTENTS/Resources/AppIcon.icns"

chmod +x "$CONTENTS/MacOS/NovaOS"
codesign --force --deep --sign - "$OUTPUT"
plutil -lint "$CONTENTS/Info.plist"
codesign --verify --deep --strict "$OUTPUT"
lipo -info "$CONTENTS/MacOS/NovaOS"
otool -L "$CONTENTS/MacOS/NovaOS" | grep Sparkle

pkgbuild --component "$OUTPUT" --install-location /Applications \
  --identifier com.novaos.desktop --version "$VERSION" "$PACKAGE"

ditto -c -k --sequesterRsrc --keepParent "$OUTPUT" "$UPDATER_ZIP"
cat > "$UPDATES/Nova OS $VERSION.html" <<HTML
<h2>Nova OS $VERSION</h2>
<ul>
  <li>Signed automatic updates are enabled through Sparkle.</li>
  <li>Open tabs and bookmarks are saved on your Mac.</li>
  <li>Recent results return instantly when you reopen a search tab.</li>
</ul>
HTML

SPARKLE_BIN="$SPM_DIR/artifacts/sparkle/Sparkle/bin"
SIGNATURE="$("$SPARKLE_BIN/sign_update" --ed-key-file "$KEY" -p "$UPDATER_ZIP")"
"$SPARKLE_BIN/sign_update" --ed-key-file "$KEY" --verify "$UPDATER_ZIP" "$SIGNATURE"
python3 "$ROOT/scripts/create-appcast.py" \
  "$UPDATER_ZIP" "$UPDATES/appcast.xml" "$VERSION" "$BUILD_NUMBER" \
  "$SIGNATURE" "$APPCAST_URL_PREFIX" "https://github.com/Ethan-cat-a/Nova-OS"

echo "Built app: $OUTPUT"
echo "Installer: $PACKAGE"
echo "Sparkle update archive: $UPDATER_ZIP"
echo "Sparkle feed: $UPDATES/appcast.xml"
echo "Build number: $BUILD_NUMBER"
