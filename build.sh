#!/bin/zsh

# Check if a package directory was provided
if [ $# -eq 0 ]; then
    echo "Please provide the directory of your Swift package."
    echo "Usage: $0 /path/to/your/package"
    exit 1
fi

PACKAGE_DIRECTORY=$1
SCHEME=$(basename "$PACKAGE_DIRECTORY")
FRAMEWORK_DIRECTORY="$PACKAGE_DIRECTORY/build/xcframework"

CONFIGURATION=Release

# Value is ignored, only the definition of the variable is considered
export SPM_GENERATE_FRAMEWORK=1

function buildframework {
    local scheme=$1
    local destination=$2
    local sdk=$3

    # build package as framework
    (cd $PACKAGE_DIRECTORY && xcodebuild -scheme $scheme -destination $destination -sdk $sdk -configuration $CONFIGURATION -derivedDataPath "${FRAMEWORK_DIRECTORY}/.build" \
        SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface" SYMROOT="$FRAMEWORK_DIRECTORY") | xcbeautify || exit -1

    BUILD_PATH=$FRAMEWORK_DIRECTORY/${CONFIGURATION}-${sdk}
    BUILD_FRAMEWORK_PATH=$BUILD_PATH/PackageFrameworks/${scheme}.framework/
    BUILD_FRAMEWORK_HEADERS=$BUILD_FRAMEWORK_PATH/Headers

    mkdir -p $BUILD_FRAMEWORK_HEADERS
    SWIFT_HEADER="${FRAMEWORK_DIRECTORY}/.build/Build/Intermediates.noindex/$scheme.build/${CONFIGURATION}-${sdk}/$scheme.build/Objects-normal/arm64/${scheme}-Swift.h"

    if [ -f "$SWIFT_HEADER" ]; then
        cp -p $SWIFT_HEADER $BUILD_FRAMEWORK_HEADERS || exit -2
    fi

    # copy package headers (if any) to generated framework
    PACKAGE_INCLUDE_DIRS=$(find $PACKAGE_DIRECTORY -path "*/Sources/*/include" -type d)

    if [ -n "$PACKAGE_INCLUDE_DIRS" ]; then
        cp -prv $PACKAGE_DIRECTORY/Sources/*/include/* $BUILD_FRAMEWORK_HEADERS || exit -2
    fi
   
    # handle swiftmodule or modulemap file
    mkdir -p $BUILD_FRAMEWORK_PATH/Modules
   
    SWIFT_MODULE_DIRECTORY=$BUILD_PATH/${scheme}.swiftmodule
   
    if [ -d $SWIFT_MODULE_DIRECTORY ]; then
        cp -prv $SWIFT_MODULE_DIRECTORY $BUILD_FRAMEWORK_PATH/Modules
    else
        # create module.modulemap file
        echo "framework module $scheme {
umbrella \"Headers\"
export *

module * { export * }
}" > $BUILD_FRAMEWORK_PATH/Modules/module.modulemap
    fi

    # Copy bundle
    BUNDLE_DIRECTORY=$BUILD_PATH/${scheme}_${scheme}.bundle
    if [ -d $BUNDLE_DIRECTORY ]; then
        cp -prv $BUNDLE_DIRECTORY $BUILD_FRAMEWORK_PATH
    fi
}

# Create output directory
mkdir -p $FRAMEWORK_DIRECTORY

# Build for iOS devices and simulator
buildframework $SCHEME "generic/platform=iOS" "iphoneos"
buildframework $SCHEME "generic/platform=iOS Simulator" "iphonesimulator"

# Create XCFramework
xcodebuild -create-xcframework \
    -framework "${FRAMEWORK_DIRECTORY}/${CONFIGURATION}-iphoneos/PackageFrameworks/${SCHEME}.framework" \
    -framework "${FRAMEWORK_DIRECTORY}/${CONFIGURATION}-iphonesimulator/PackageFrameworks/${SCHEME}.framework" \
    -output "${FRAMEWORK_DIRECTORY}/${SCHEME}.xcframework"

echo "XCFramework created at: ${FRAMEWORK_DIRECTORY}/${SCHEME}.xcframework"
