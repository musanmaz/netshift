#!/bin/bash
set -e

APP_NAME="NetShift"
BUNDLE_NAME="DNSHelper"
BUILD_DIR=".build/release"
APP_DIR="build/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf "build/"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BUILD_DIR}/${BUNDLE_NAME}" "${APP_DIR}/Contents/MacOS/${BUNDLE_NAME}"
cp "DNSHelper/Info.plist" "${APP_DIR}/Contents/Info.plist"

cat > "${APP_DIR}/Contents/PkgInfo" << 'EOF'
APPL????
EOF

echo "App bundle created at: ${APP_DIR}"
echo "Running ${APP_NAME}..."
open "${APP_DIR}"
