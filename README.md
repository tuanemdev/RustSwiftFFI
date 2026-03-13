# Rust Swift FFI

A Swift Package that exposes Rust logic via UniFFI, distributed as an XCFramework.

---

## Prerequisites

- [Rust](https://www.rust-lang.org/tools/install)
- Xcode Command Line Tools (`xcode-select --install`)
- A valid Apple Developer certificate installed in your Keychain (required only for signing)

---

## Building

### 1. Clone the repository

```bash
git clone https://github.com/tuanemdev/RustSwiftFFI.git
cd RustSwiftFFI
```

### 2. Run the build script

```bash
./build_xcframework.sh
```

This will:
1. Install the required Rust targets (`aarch64-apple-ios`, `aarch64-apple-ios-sim`, `aarch64-apple-darwin`)
2. Compile the Rust library for each target in release mode
3. Generate Swift bindings, C headers, and a modulemap via UniFFI
4. Bundle everything into `build/rust_swiftFFI.xcframework`
5. Copy the Swift wrapper to `build/RustSwift.swift`

### 3. Output files

| File | Description |
|------|-------------|
| `build/rust_swiftFFI.xcframework` | XCFramework containing static libraries for iOS, iOS Simulator, and macOS |
| `build/RustSwift.swift` | Generated Swift wrapper to include in your app target |

---

## Code Signing

By default, signing is **skipped**. To sign the XCFramework (required for App Store distribution):

**Step 1 — Find your signing identity:**

```bash
security find-identity -v -p codesigning
```

You will see output like:
```
1) XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX "Apple Development: Nguyen Van A (TEAMID)"
```

**Step 2 — Run the build with your identity:**

```bash
SIGNING_IDENTITY="Apple Development: Nguyen Van A (TEAMID)" ./build_xcframework.sh
```

Or export it for the current shell session:

```bash
export SIGNING_IDENTITY="Apple Development: Nguyen Van A (TEAMID)"
./build_xcframework.sh
```

**Step 3 — Verify the signature:**

```bash
codesign -dvvv build/rust_swiftFFI.xcframework
```

---

## Distributing & Integrating via Swift Package Manager (Remote Binary Target)

SPM recommends distributing XCFrameworks as a **remote** binary target — a zipped `.xcframework` hosted at a public URL with a SHA-256 checksum for verification. Do **not** commit the `.xcframework` directly into the repository.

### Step 1 — Zip the XCFramework

```bash
cd build
zip -r rust_swiftFFI.xcframework.zip rust_swiftFFI.xcframework
```

### Step 2 — Compute the SHA-256 checksum

```bash
swift package compute-checksum build/rust_swiftFFI.xcframework.zip
```

Copy the printed hash (e.g. `a1b2c3d4e5f6...`).

### Step 3 — Upload the zip

Upload `rust_swiftFFI.xcframework.zip` to a publicly accessible URL, such as a **GitHub Release asset**:

1. Create a new GitHub Release for your repository
2. Attach `rust_swiftFFI.xcframework.zip` as a release asset
3. Copy the download URL (e.g. `https://github.com/your-org/your-repo/releases/download/1.0.0/rust_swiftFFI.xcframework.zip`)

### Step 4 — Declare the binary target in `Package.swift`

```swift
.binaryTarget(
    name: "rust_swiftFFI",
    url: "https://github.com/your-org/your-repo/releases/download/1.0.0/rust_swiftFFI.xcframework.zip",
    checksum: "a1b2c3d4e5f6..."  // paste the hash from Step 2
)
```

### Step 5 — Add the Swift wrapper

Commit `build/RustSwift.swift` into your package repository and add it to your library's source target in `Package.swift`.

---

Simply call the exposed functions directly from your own Swift code:

```swift
let result = addCoreLogic(left: 1, right: 2)
let greeting = sayHiFromRust()
```

---

## Example Implementation

See the [RustSwiftFFI-SPM](https://github.com/tuanemdev/RustSwiftFFI-SPM) repository for a complete example of how to integrate this XCFramework into a Swift Package Manager project.

---

## Documentation & References

[UniFFI-rs](https://github.com/mozilla/uniffi-rs) – Official Mozilla UniFFI documentation and source code
