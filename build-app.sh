#!/bin/bash
set -e

APP_NAME="NetShift"
BUNDLE_NAME="DNSHelper"
BUILD_DIR=".build/release"
APP_DIR="build/${APP_NAME}.app"
ICON_SRC="DNSHelper/Resources/Assets.xcassets/AppIcon.appiconset"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf "build/"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BUILD_DIR}/${BUNDLE_NAME}" "${APP_DIR}/Contents/MacOS/${BUNDLE_NAME}"
cp "DNSHelper/Info.plist" "${APP_DIR}/Contents/Info.plist"

# Copy SPM resource bundle (needed for Bundle.module at runtime)
RESOURCE_BUNDLE="${BUILD_DIR}/${BUNDLE_NAME}_${BUNDLE_NAME}.bundle"
if [ -d "${RESOURCE_BUNDLE}" ]; then
    cp -R "${RESOURCE_BUNDLE}" "${APP_DIR}/Contents/Resources/"
fi

# Create .icns from icon PNGs
echo "Creating app icon..."
ICONSET_DIR=$(mktemp -d)/AppIcon.iconset
mkdir -p "${ICONSET_DIR}"

cp "${ICON_SRC}/icon_16x16.png"    "${ICONSET_DIR}/icon_16x16.png"
cp "${ICON_SRC}/icon_32x32.png"    "${ICONSET_DIR}/icon_16x16@2x.png"
cp "${ICON_SRC}/icon_32x32.png"    "${ICONSET_DIR}/icon_32x32.png"
cp "${ICON_SRC}/icon_64x64.png"    "${ICONSET_DIR}/icon_32x32@2x.png"
cp "${ICON_SRC}/icon_128x128.png"  "${ICONSET_DIR}/icon_128x128.png"
cp "${ICON_SRC}/icon_256x256.png"  "${ICONSET_DIR}/icon_128x128@2x.png"
cp "${ICON_SRC}/icon_256x256.png"  "${ICONSET_DIR}/icon_256x256.png"
cp "${ICON_SRC}/icon_512x512.png"  "${ICONSET_DIR}/icon_256x256@2x.png"
cp "${ICON_SRC}/icon_512x512.png"  "${ICONSET_DIR}/icon_512x512.png"
cp "${ICON_SRC}/icon_1024x1024.png" "${ICONSET_DIR}/icon_512x512@2x.png"

iconutil -c icns "${ICONSET_DIR}" -o "${APP_DIR}/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "${ICONSET_DIR}")"

printf 'APPL????' > "${APP_DIR}/Contents/PkgInfo"

# Ad-hoc code sign so macOS doesn't treat it as damaged
echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "${APP_DIR}"

echo "App bundle created at: ${APP_DIR}"
echo "Running ${APP_NAME}..."
open "${APP_DIR}"
