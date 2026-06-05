#!/usr/bin/env bash
# build-ipa.sh
# 直接用 swiftc 编译 + 手工组装 .app + zip 成未签名 IPA
# 不依赖 xcodebuild 的 destination 机制（绕过 Xcode 26 platform 检查）
#
# 用法：
#   bash scripts/build-ipa.sh
# 产物：
#   build/PhotoCleaner.ipa   （未签名）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$PROJECT_DIR/PhotoCleaner"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/PhotoCleaner.app"
IPA_PATH="$BUILD_DIR/PhotoCleaner.ipa"

# 配置
BUNDLE_ID="com.maizhenying.PhotoCleaner"
APP_NAME="PhotoCleaner"
MIN_IOS="17.0"
SDK_NAME="iphoneos26.5"
TARGET="arm64-apple-ios${MIN_IOS}"

cd "$PROJECT_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR"

# 收集所有 swift 源文件
SWIFT_FILES=(
  "$SRC_DIR/PhotoCleanerApp.swift"
  "$SRC_DIR/Models/PhotoCategory.swift"
  "$SRC_DIR/Services/PhotoLibraryService.swift"
  "$SRC_DIR/Services/PhotoClassifier.swift"
  "$SRC_DIR/ViewModels/SwipeReviewViewModel.swift"
  "$SRC_DIR/Views/RootView.swift"
  "$SRC_DIR/Views/CategoryListView.swift"
  "$SRC_DIR/Views/SwipeReviewView.swift"
  "$SRC_DIR/Views/PendingDeletionView.swift"
  "$SRC_DIR/Views/Components/LiquidGlassCard.swift"
  "$SRC_DIR/Views/Components/PhotoCardView.swift"
  "$SRC_DIR/Views/Components/FloatingTabBar.swift"
)

SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"
echo "SDK: $SDK_PATH"

echo "==> 1/3 swiftc 编译 + 链接为 PhotoCleaner 可执行文件"
xcrun --sdk "$SDK_NAME" swiftc \
  -target "$TARGET" \
  -sdk "$SDK_PATH" \
  -O \
  -whole-module-optimization \
  -emit-executable \
  -o "$APP_DIR/PhotoCleaner" \
  "${SWIFT_FILES[@]}"

echo "==> 2/3 拷贝 Info.plist 到 .app"
# Info.plist 需要二进制 / 标准格式都行；我们用 plutil 转成 binary（更紧凑）
plutil -convert binary1 -o "$APP_DIR/Info.plist" "$SRC_DIR/Info.plist"
# 注意：Info.plist 里的 $(...) 变量需要解析
# 用 sed 替换关键变量
plutil -replace CFBundleExecutable -string "$APP_NAME" "$APP_DIR/Info.plist"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP_DIR/Info.plist"
plutil -replace CFBundleName -string "$APP_NAME" "$APP_DIR/Info.plist"
plutil -replace CFBundlePackageType -string "APPL" "$APP_DIR/Info.plist"
plutil -replace CFBundleDevelopmentRegion -string "en" "$APP_DIR/Info.plist"
plutil -replace MinimumOSVersion -string "$MIN_IOS" "$APP_DIR/Info.plist"
plutil -replace DTPlatformName -string "iphoneos" "$APP_DIR/Info.plist"

echo "==> 3/3 打包 Payload/ → .ipa"
PAYLOAD_DIR="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"
cp -R "$APP_DIR" "$PAYLOAD_DIR/"

cd "$BUILD_DIR"
zip -qry "$IPA_PATH" Payload
rm -rf Payload

echo ""
echo "✅ 完成"
echo "   未签名 .app: $APP_DIR"
echo "   未签名 IPA:  $IPA_PATH"
echo ""
ls -la "$IPA_PATH"
echo ""
echo "下一步：用 Sideloadly / AltStore / Xcode 直签后安装到真机。"
echo "详见 README.md。"
