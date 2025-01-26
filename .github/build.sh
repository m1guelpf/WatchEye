#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PROJECT_BUILD_DIR="${PROJECT_BUILD_DIR:-"${PROJECT_ROOT}/build"}"
XCODEBUILD_BUILD_DIR="$PROJECT_BUILD_DIR/xcodebuild"
XCODEBUILD_DERIVED_DATA_PATH="$XCODEBUILD_BUILD_DIR/DerivedData"

build_framework() {
    local sdk="$1"
    local destination="$2"
    local scheme="$3"

    local XCODEBUILD_ARCHIVE_PATH="./$scheme-$sdk.xcarchive"

    rm -rf "$XCODEBUILD_ARCHIVE_PATH"

    xcodebuild archive \
        -scheme "$scheme" \
        -archivePath "$XCODEBUILD_ARCHIVE_PATH" \
        -derivedDataPath "$XCODEBUILD_DERIVED_DATA_PATH" \
        -sdk "$sdk" \
        -destination "$destination" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        INSTALL_PATH='Library/Frameworks' \
        OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface \
        LD_GENERATE_MAP_FILE=YES

    FRAMEWORK_MODULES_PATH="$XCODEBUILD_ARCHIVE_PATH/Products/Library/Frameworks/$scheme.framework/Modules"
    mkdir -p "$FRAMEWORK_MODULES_PATH"
    cp -r \
    "$XCODEBUILD_DERIVED_DATA_PATH/Build/Intermediates.noindex/ArchiveIntermediates/$scheme/BuildProductsPath/Release/$scheme.swiftmodule" \
    "$FRAMEWORK_MODULES_PATH/$scheme.swiftmodule"
    # Delete private swiftinterface
    rm -f "$FRAMEWORK_MODULES_PATH/$scheme.swiftmodule/*.private.swiftinterface"
    mkdir -p "$scheme-$sdk.xcarchive/LinkMaps"
    find "$XCODEBUILD_DERIVED_DATA_PATH" -name "$scheme-LinkMap-*.txt" -exec cp {} "./$scheme-$sdk.xcarchive/LinkMaps/" \;
}

# Update the Package.swift to build the library as dynamic instead of static
sed -i '' 's/type: \.static/type: .dynamic/g' Package.swift

build_framework "macosx" "generic/platform=macOS" "WatchEye"

echo "Builds completed successfully."

rm -rf "WatchEye.xcframework"
xcodebuild -create-xcframework -framework WatchEye-macosx.xcarchive/Products/Library/Frameworks/WatchEye.framework -output WatchEye.xcframework

cp -r WatchEye-macosx.xcarchive/dSYMs WatchEye.xcframework/macos-arm64
