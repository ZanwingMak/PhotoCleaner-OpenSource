#!/usr/bin/env bash
# build-ipa.sh
# swiftc 编译 + actool 编译 AppIcon → Assets.car + 组装 .app + zip 成未签名 IPA

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$PROJECT_DIR/PhotoCleaner"
BUILD_DIR="$PROJECT_DIR/build"
ICONS_DIR="$BUILD_DIR/icons"
ACTOOL_OUT="$BUILD_DIR/actool-out"
APP_DIR="$BUILD_DIR/PhotoCleaner.app"

VERSION="$(grep -m1 -oE '## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$PROJECT_DIR/CHANGELOG.md" | head -1 | tr -d '[]## ')"
if [ -z "$VERSION" ]; then VERSION="0.0.0"; fi

IPA_PATH="$BUILD_DIR/PhotoCleaner-v${VERSION}.ipa"

BUNDLE_ID="app.photocleaner.PhotoCleaner"
APP_NAME="PhotoCleaner"
APP_DISPLAY_NAME="Photo Cleaner"
MIN_IOS="17.0"
SDK_NAME="iphoneos26.5"
TARGET="arm64-apple-ios${MIN_IOS}"

cd "$PROJECT_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR" "$ICONS_DIR" "$ACTOOL_OUT"

SWIFT_FILES=(
  "$SRC_DIR/PhotoCleanerApp.swift"
  "$SRC_DIR/Models/PhotoCategory.swift"
  "$SRC_DIR/Services/PhotoLibraryService.swift"
  "$SRC_DIR/Services/PhotoClassifier.swift"
  "$SRC_DIR/Services/ThemeManager.swift"
  "$SRC_DIR/Services/LanguageManager.swift"
  "$SRC_DIR/Services/L10n.swift"
  "$SRC_DIR/Services/UpdateChecker.swift"
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
  "$SRC_DIR/Views/Components/LivePhotoView.swift"
  "$SRC_DIR/Views/Components/CustomDialog.swift"
)

SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"

echo "==> 1/6 swiftc 编译 + 链接"
xcrun --sdk "$SDK_NAME" swiftc \
  -target "$TARGET" \
  -sdk "$SDK_PATH" \
  -O -whole-module-optimization \
  -emit-executable \
  -o "$APP_DIR/PhotoCleaner" \
  "${SWIFT_FILES[@]}"

echo "==> 2/6 生成 AppIcon 1024 主图"
swift "$SCRIPT_DIR/generate-icon.swift" "$ICONS_DIR/AppIcon-1024.png" >/dev/null
# 同步到 Assets.xcassets（确保 actool 用最新图）
cp "$ICONS_DIR/AppIcon-1024.png" "$SRC_DIR/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

echo "==> 3/6 actool 编译 Assets.xcassets → Assets.car"
xcrun actool "$SRC_DIR/Assets.xcassets" \
  --compile "$ACTOOL_OUT" \
  --platform iphoneos \
  --target-device iphone \
  --target-device ipad \
  --minimum-deployment-target "$MIN_IOS" \
  --app-icon AppIcon \
  --output-format human-readable-text \
  --output-partial-info-plist "$ACTOOL_OUT/partial.plist" \
  --compress-pngs >/dev/null

# 把所有 actool 产物拷到 .app（Assets.car 是关键）
cp -R "$ACTOOL_OUT/"*.png "$APP_DIR/" 2>/dev/null || true
cp "$ACTOOL_OUT/Assets.car" "$APP_DIR/"

echo "==> 4/6 组装 Info.plist（合并 actool partial.plist 的 AppIcon 配置）"
plutil -convert binary1 -o "$APP_DIR/Info.plist" "$SRC_DIR/Info.plist"
plutil -replace CFBundleExecutable -string "$APP_NAME" "$APP_DIR/Info.plist"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP_DIR/Info.plist"
plutil -replace CFBundleName -string "$APP_NAME" "$APP_DIR/Info.plist"
plutil -replace CFBundleDisplayName -string "$APP_DISPLAY_NAME" "$APP_DIR/Info.plist"
plutil -replace CFBundlePackageType -string "APPL" "$APP_DIR/Info.plist"
plutil -replace CFBundleDevelopmentRegion -string "en" "$APP_DIR/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP_DIR/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP_DIR/Info.plist"
plutil -replace MinimumOSVersion -string "$MIN_IOS" "$APP_DIR/Info.plist"
plutil -replace DTPlatformName -string "iphoneos" "$APP_DIR/Info.plist"

# 合并 actool 的 CFBundleIcons 配置（含 CFBundleIconName，主屏识别图标的关键）
# 用 python 合并两个 plist
python3 -c "
import plistlib
with open('$APP_DIR/Info.plist', 'rb') as f:
    main = plistlib.load(f)
with open('$ACTOOL_OUT/partial.plist', 'rb') as f:
    partial = plistlib.load(f)
main.update(partial)
with open('$APP_DIR/Info.plist', 'wb') as f:
    plistlib.dump(main, f, fmt=plistlib.FMT_BINARY)
"

echo "==> 拷贝本地化资源"
find "$SRC_DIR" -maxdepth 1 -type d -name "*.lproj" -exec cp -R {} "$APP_DIR/" \;

echo "==> 5/6 打包 Payload/ → .ipa"
PAYLOAD_DIR="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"
cp -R "$APP_DIR" "$PAYLOAD_DIR/"

cd "$BUILD_DIR"
zip -qry "$IPA_PATH" Payload
rm -rf Payload

echo "==> 6/6 完成"
ls -la "$IPA_PATH"
echo ""
echo "✅ 未签名 .app: $APP_DIR"
echo "✅ 未签名 IPA:  $IPA_PATH"
echo ""
echo "Assets.car: $(ls -la "$APP_DIR/Assets.car" | awk '{print $5}') bytes"
echo "Info.plist CFBundleIconName: $(plutil -extract 'CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName' raw -o - "$APP_DIR/Info.plist")"
