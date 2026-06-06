# PhotoCleaner

[中文](README.md) · **English** · [日本語](README.ja.md) · [한국어](README.ko.md)

> Slidebox-like iOS photo organizer. Native SwiftUI with iOS 26 Liquid Glass.

![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- 📷 Reads system photo library, classified by smart albums + metadata inference
- 👉 **Swipe to review**: left = next, right = previous, up = mark delete
- 🗑 **Pending list** with batch confirmation + native iOS delete dialog
- ⏪ Single-step undo
- 🖼 **Photo browser**: full-screen view, zoom, swipe pagination, favorite / share / jump to Photos.app
- 📊 **Metadata sheet**: size, file size, type, location, duration
- 🌗 **5 themes**: System / Dark / Light / Caramel / Cool
- 🌐 **4 languages**: 中文 / English / 日本語 / 한국어
- ✨ iOS 26 Liquid Glass + custom AppIcon
- 🔒 100% on-device, zero uploads

## Project Structure

See [中文 README](README.md#项目结构) for the directory tree (identical).

## Run in Simulator

```bash
# Requires Xcode 26+ and an iOS Simulator runtime
open PhotoCleaner.xcodeproj
# Press ⌘R in Xcode
```

## Build Unsigned IPA

```bash
bash scripts/build-ipa.sh
# Output: build/PhotoCleaner-v<VERSION>.ipa
```

## Install on a Device (No Developer Account)

The IPA is unsigned. Use one of these to self-sign with a free Apple ID (7-day cert):

### Option A: Sideloadly (Easiest)
1. Download https://sideloadly.io
2. Drag `build/PhotoCleaner-v0.8.0.ipa` into it
3. Enter your free Apple ID
4. On iPhone: Settings → General → VPN & Device Management → trust the certificate

### Option B: AltStore (Auto-Renew)
Use AltServer in the background to auto-refresh the 7-day cert

### Option C: Xcode Direct Sign
Open the project in Xcode, set Signing → Team to your free Apple ID, ⌘R to your device

## Privacy

- All processing is local. **Zero network uploads.**
- Only `NSPhotoLibraryUsageDescription` is requested
- Deletion triggers the native iOS confirmation dialog; the app cannot bypass it

## Links

- [CHANGELOG](CHANGELOG.md)
- [FEATURES](FEATURES.md)
- [TEST PLAN](TEST_PLAN.md)
- [Releases](https://github.com/ZanwingMak/PhotoCleaner/releases)

## License

MIT
