#!/bin/bash
set -e

# Library name
LIB_NAME="rust_swift"
FFI_MODULE="${LIB_NAME}FFI"
SWIFT_SOURCE_NAME="RustSwift"

# Code signing identity — set to empty string to skip signing.
# Example: "Apple Development: Nguyen Van A (XXXXXXXXXX)"
# You can also override at runtime: SIGNING_IDENTITY="..." ./build_xcframework.sh
SIGNING_IDENTITY="${SIGNING_IDENTITY:-""}"

# Target definitions
TARGETS=(
    "aarch64-apple-ios"
    "aarch64-apple-ios-sim"
    "aarch64-apple-darwin"
)

# Adding targets
rustup target add "${TARGETS[@]}"

# Building Rust libraries for each target
for TARGET in "${TARGETS[@]}"; do
    cargo build --target "$TARGET" --release
done

OUT_DIR="build/swift"
mkdir -p "$OUT_DIR/Headers"

FIRST_TARGET="${TARGETS[0]}"
LIB_PATH="target/$FIRST_TARGET/release/lib${LIB_NAME}.a"

# Generate Swift source files
cargo run --bin uniffi-bindgen-swift -- "$LIB_PATH" "$OUT_DIR" --swift-sources

# Generate headers
cargo run --bin uniffi-bindgen-swift -- "$LIB_PATH" "$OUT_DIR/Headers" --headers

# Generate modulemap
cargo run --bin uniffi-bindgen-swift -- "$LIB_PATH" "$OUT_DIR/Headers" --modulemap --module-name "$FFI_MODULE" --modulemap-filename module.modulemap

# Create XCFramework
rm -rf "build/${FFI_MODULE}.xcframework"
rm -rf "build/${SWIFT_SOURCE_NAME}.swift"

XCFRAMEWORK_ARGS=()
for TARGET in "${TARGETS[@]}"; do
    XCFRAMEWORK_ARGS+=(-library "target/$TARGET/release/lib${LIB_NAME}.a" -headers "$OUT_DIR/Headers")
done

xcodebuild -create-xcframework \
    "${XCFRAMEWORK_ARGS[@]}" \
    -output "build/${FFI_MODULE}.xcframework"

cp "$OUT_DIR"/*.swift "build/${SWIFT_SOURCE_NAME}.swift"

rm -rf build/swift

# Sign XCFramework
if [ -n "$SIGNING_IDENTITY" ]; then
    echo "Signing XCFramework with identity: $SIGNING_IDENTITY"
    codesign --timestamp -s "$SIGNING_IDENTITY" "build/${FFI_MODULE}.xcframework"
else
    echo "No SIGNING_IDENTITY set, skipping code signing."
fi

echo "Done! XCFramework generated at build/${FFI_MODULE}.xcframework and bindings at build/${SWIFT_SOURCE_NAME}.swift"
