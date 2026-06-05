#!/usr/bin/env bash
# build-ipa.sh
# swiftc 编译 + 手工组装 .app（含 AppIcon）+ zip 成未签名 IPA
#
# 用法：bash scripts/build-ipa.sh
# 产物：build/PhotoCleaner.ipa（未签名）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$PROJECT_DIR/PhotoCleaner"
BUILD_DIR="$PROJECT_DIR/build"
ICONS_DIR="$BUILD_DIR/icons"
APP_DIR="$BUILD_DIR/PhotoCleaner.app"
IPA_PATH="$BUILD_DIR/PhotoCleaner.ipa"

BUNDLE_ID="com.maizhenying.PhotoCleaner"
APP_NAME="PhotoCleaner"
MIN_IOS="17.0"
SDK_NAME="iphoneos26.5"
TARGET="arm64-apple-ios${MIN_IOS}"

cd "$PROJECT_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR" "$ICONS_DIR"

SWIFT_FILES=(
  "$SRC_DIR/PhotoCleanerApp.swift"
  "$SRC_DIR/Models/PhotoCategory.swift"
  "$SRC_DIR/Services/PhotoLibraryService.swift"
  "$SRC_DIR/Services/PhotoClassifier.swift"
  "$SRC_DIR/Services/ThemeManager.swift"
  "$SRC_DIR/ViewModels/SwipeReviewViewModel.swift"
  "$SRC_DIR/Views/RootView.swift"
  "$SRC_DIR/Views/CategoryListView.swift"
  "$SRC_DIR/Views/SwipeReviewView.swift"
  "$SRC_DIR/Views/PendingDeletionView.swift"
  "$SRC_DIR/Views/PhotosBrowserView.swift"
  "$SRC_DIR/Views/SettingsView.swift"
  "$SRC_DIR/Views/PhotoMetadataSheet.swift"
  "$SRC_DIR/Views/PhotoDetailView.swift"
  "$SRC_DIR/Views/Components/LiquidGlassCard.swift"
  "$SRC_DIR/Views/Components/PhotoCardView.swift"
  "$SRC_DIR/Views/Components/FloatingTabBar.swift"
  "$SRC_DIR/Views/Components/ToastView.swift"
  "$SRC_DIR/Views/Components/RingProgress.swift"
  "$SRC_DIR/Views/Components/AppPalette.swift"
)

SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"

echo "==> 1/5 swiftc 编译 + 链接"
xcrun --sdk "$SDK_NAME" swiftc \
  -target "$TARGET" \
  -sdk "$SDK_PATH" \
  -O \
  -whole-module-optimization \
  -emit-executable \
  -o "$APP_DIR/PhotoCleaner" \
  "${SWIFT_FILES[@]}"

echo "==> 2/5 生成 AppIcon (1024 → 各尺寸)"
swift "$SCRIPT_DIR/generate-icon.swift" "$ICONS_DIR/AppIcon-1024.png" >/dev/null

# Apple 命名规范：CFBundleIcons 引用前缀，运行时根据 @2x/@3x 选择
# iPhone 60pt @2x=120 @3x=180  iPad 76pt @2x=152  iPad Pro 83.5pt @2x=167
sips -z 120 120 "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon60x60@2x.png" >/dev/null
sips -z 180 180 "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon60x60@3x.png" >/dev/null
sips -z 76 76   "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon76x76~ipad.png" >/dev/null
sips -z 152 152 "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon76x76@2x~ipad.png" >/dev/null
sips -z 167 167 "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon83.5x83.5@2x~ipad.png" >/dev/null
# 小图标（设置、Spotlight）
sips -z 58 58   "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon29x29@2x.png" >/dev/null
sips -z 87 87   "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon29x29@3x.png" >/dev/null
sips -z 80 80   "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon40x40@2x.png" >/dev/null
sips -z 120 120 "$ICONS_DIR/AppIcon-1024.png" --out "$APP_DIR/AppIcon40x40@3x.png" >/dev/null

echo "==> 3/5 拷贝并配置 Info.plist"
plutil -convert binary1 -o "$APP_DIR/Info.plist" "$SRC_DIR/Info.plist"
plutil -replace CFBundleExecutable -string "$APP_NAME" "$APP_DIR/Info.plist"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP_DIR/Info.plist"
plutil -replace CFBundleName -string "$APP_NAME" "$APP_DIR/Info.plist"
plutil -replace CFBundlePackageType -string "APPL" "$APP_DIR/Info.plist"
plutil -replace CFBundleDevelopmentRegion -string "en" "$APP_DIR/Info.plist"
plutil -replace MinimumOSVersion -string "$MIN_IOS" "$APP_DIR/Info.plist"
plutil -replace DTPlatformName -string "iphoneos" "$APP_DIR/Info.plist"

# AppIcon 字典（iPhone）
plutil -insert CFBundleIcons -xml '
<dict>
  <key>CFBundlePrimaryIcon</key>
  <dict>
    <key>CFBundleIconFiles</key>
    <array>
      <string>AppIcon60x60</string>
      <string>AppIcon29x29</string>
      <string>AppIcon40x40</string>
    </array>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
  </dict>
</dict>' "$APP_DIR/Info.plist" 2>/dev/null || true

# AppIcon 字典（iPad）
plutil -insert "CFBundleIcons~ipad" -xml '
<dict>
  <key>CFBundlePrimaryIcon</key>
  <dict>
    <key>CFBundleIconFiles</key>
    <array>
      <string>AppIcon60x60</string>
      <string>AppIcon76x76</string>
      <string>AppIcon83.5x83.5</string>
      <string>AppIcon29x29</string>
      <string>AppIcon40x40</string>
    </array>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
  </dict>
</dict>' "$APP_DIR/Info.plist" 2>/dev/null || true

echo "==> 4/5 打包 Payload/ → .ipa"
PAYLOAD_DIR="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"
cp -R "$APP_DIR" "$PAYLOAD_DIR/"

cd "$BUILD_DIR"
zip -qry "$IPA_PATH" Payload
rm -rf Payload

echo "==> 5/5 完成"
ls -la "$IPA_PATH"
echo ""
echo "✅ 未签名 .app: $APP_DIR"
echo "✅ 未签名 IPA:  $IPA_PATH"
echo ""
echo "下一步：用 Sideloadly / AltStore / Xcode 直签后安装到真机。"
