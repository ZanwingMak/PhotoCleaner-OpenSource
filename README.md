<p align="center">
  <img src="docs/icon.png" width="128" alt="PhotoCleaner icon" />
</p>

<h1 align="center">PhotoCleaner</h1>

<p align="center"><b>English</b> · <a href="README.zh.md">中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a></p>

> Slidebox-like iOS photo organizer. Native SwiftUI with iOS 26 Liquid Glass.

![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)
![License](https://img.shields.io/badge/license-GPL--3.0-blue)
![Version](https://img.shields.io/badge/version-1.1.9-success)

## Features

- 📷 Reads system photo library, classified by smart albums + metadata inference
- 👉 **Swipe to review**: left = next, right = previous, up = mark delete
- 🗑 **Pending delete list** with batch confirmation + native iOS delete dialog
- ⏪ Single-step undo
- 🖼 **Photo browser**: full-screen view, zoom, swipe pagination, favorite / share / open in Photos.app
- 📊 **Metadata sheet**: dimensions, file size, type, location, duration
- 💡 **Smart Picks**: six cleanup entry points (old screenshots / storage hogs / videos / live photos / selfies / low-res images), horizontal cards on home + a "More" sheet for the full list
- 🌗 **5 themes**: System / Dark / Light / Caramel / Cool
- 🌐 **4 languages**: 中文 / English / 日本語 / 한국어
- ⬆️ **Update check**: silently queries GitHub Releases on entering Settings; highlights a chip in the About section when a newer version is published
- ✨ iOS 26 Liquid Glass + custom AppIcon
- 🔒 100% on-device, zero uploads

## Screenshots

<p align="center">
  <img src="docs/screenshots/01-home.png" width="240" alt="Home — Smart Picks, Time Lens, Bento categories" />
  <img src="docs/screenshots/02-albums.png" width="240" alt="Albums — smart albums and inferred cleanup categories" />
  <img src="docs/screenshots/03-settings.png" width="240" alt="Settings — themes, languages, and experience toggles" />
</p>

> Left → Right: home screen with Smart Picks and Time Lens · albums list with smart albums and cleanup categories · settings page with themes, languages, and experience toggles.

## Project Structure

```
PhotoCleaner/
├── PhotoCleaner.xcodeproj
├── PhotoCleaner/
│   ├── PhotoCleanerApp.swift          App entry + RootShell (injects system colorScheme)
│   ├── Info.plist                     Permission declarations
│   ├── Models/PhotoCategory.swift     Category enum
│   ├── Services/
│   │   ├── PhotoLibraryService.swift  PhotosKit wrapper
│   │   ├── PhotoClassifier.swift      Metadata inference
│   │   ├── ThemeManager.swift         Theme persistence
│   │   ├── LanguageManager.swift      Language persistence
│   │   ├── L10n.swift                 Translation dictionary
│   │   └── UpdateChecker.swift        GitHub Releases version check
│   ├── ViewModels/
│   └── Views/
│       ├── RootView.swift             Permission routing
│       ├── CategoryListView.swift     Home (incl. Smart Picks "More" sheet)
│       ├── SwipeReviewView.swift      Swipe review
│       ├── PendingDeletionView.swift  Pending delete list
│       ├── PhotosBrowserView.swift    Photo browser
│       ├── PhotoDetailView.swift      Full-screen viewer
│       ├── PhotoMetadataSheet.swift   Metadata detail
│       ├── SettingsView.swift         Settings
│       └── Components/                Shared UI
├── scripts/
│   ├── build-ipa.sh                   One-shot unsigned IPA build
│   └── generate-icon.swift            AppIcon generator
├── CHANGELOG.md                       Version history
├── FEATURES.md                        Feature spec
├── TEST_PLAN.md                       Test cases
└── README.md                          You are here
```

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

The IPA is unsigned. Pick one of these to self-sign with a free Apple ID (cert valid 7 days):

### Option A: Sideloadly (Easiest)
1. Download https://sideloadly.io
2. Drag `build/PhotoCleaner-v<VERSION>.ipa` into it
3. Sign in with a free Apple ID
4. On iPhone: Settings → General → VPN & Device Management → trust the certificate

### Option B: AltStore (Auto-Renew)
Run AltServer in the background to keep the 7-day cert refreshed automatically.

### Option C: Xcode Direct Sign
Open the project in Xcode, set Signing → Team to your free Apple ID, ⌘R to your device.

## Privacy

- All processing happens locally. **Zero network uploads.**
- Only `NSPhotoLibraryUsageDescription` is requested
- Deletion always triggers the native iOS confirmation dialog; the app cannot bypass it
- The update check fires a single GET to `api.github.com`. It sends only the standard User-Agent and never includes any personal data.

## Sponsor

- [PayPal](https://paypal.me/zanwing)
- [Buy me a coffee](https://buymeacoffee.com/zanwing)
- [Wise](https://wise.com/pay/me/zhenyingm1)
- WeChat Reward Code and Alipay QR are available in Settings → Sponsor.

## Links

- [Official Website](https://zanwingmak.github.io/PhotoCleaner/)
- [CHANGELOG](CHANGELOG.md)
- [FEATURES](FEATURES.md)
- [TEST PLAN](TEST_PLAN.md)
- [Releases](https://github.com/ZanwingMak/PhotoCleaner/releases)

## License

GPL-3.0-only
