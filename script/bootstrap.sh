#!/bin/bash
set -euo pipefail

MAS_VERSION="2.4.0"
CHECKOUT_DIR="Carthage/Checkouts/MASShortcut"
BUILD_DIR="Carthage/Build/Mac"

echo "Setting up MASShortcut dependency..."
mkdir -p Carthage/Checkouts
if [ ! -d "$CHECKOUT_DIR" ]; then
    git clone --depth 1 --branch "$MAS_VERSION" https://github.com/shpakovski/MASShortcut.git "$CHECKOUT_DIR"
fi

echo "Building MASShortcut Universal Framework..."
xcodebuild -project "$CHECKOUT_DIR/MASShortcut.xcodeproj" \
    -scheme MASShortcut \
    -configuration Release \
    MACOSX_DEPLOYMENT_TARGET=11.0 \
    ONLY_ACTIVE_ARCH=NO \
    GCC_TREAT_WARNINGS_AS_ERRORS=NO \
    -derivedDataPath Carthage/DerivedData \
    build

mkdir -p "$BUILD_DIR"
rm -rf "$BUILD_DIR/MASShortcut.framework"
cp -R Carthage/DerivedData/Build/Products/Release/MASShortcut.framework "$BUILD_DIR/"
rm -rf Carthage/DerivedData

echo "MASShortcut built successfully at $BUILD_DIR/MASShortcut.framework"
