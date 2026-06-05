# PhotoCleaner

类 Slidebox 的 iOS 照片整理应用。SwiftUI 原生实现，对应 iOS 26 液态玻璃语言。

## 功能

- 读取系统照片库，按系统智能相册 + 元数据推断双重分类（截图 / 自拍 / 相机原图 / 社交媒体 / 大文件 / 收藏 / 视频 / 实况 / 最近添加 / 横屏 / 竖屏）
- 卡牌堆叠界面：**左/右滑** 保留，**上滑** 加入待删除列表
- 待删除列表可逐张取消、可批量确认，最终由系统弹原生确认对话框
- 支持撤销上一步、显示当前进度、显示每张图分辨率与文件大小
- 完整 iOS 26 液态玻璃 (`glassEffect`)，并向下兼容到 iOS 17 (降级到 `ultraThinMaterial`)
- 深浅色自动跟随系统

## 项目结构

```
PhotoCleaner/
├── PhotoCleaner.xcodeproj
├── PhotoCleaner/
│   ├── PhotoCleanerApp.swift          应用入口
│   ├── Info.plist                     权限声明 (NSPhotoLibraryUsageDescription)
│   ├── Models/PhotoCategory.swift     分类枚举
│   ├── Services/
│   │   ├── PhotoLibraryService.swift  PhotosKit 封装（授权/查询/删除）
│   │   └── PhotoClassifier.swift      基于元数据的来源推断
│   ├── ViewModels/SwipeReviewViewModel.swift
│   └── Views/
│       ├── RootView.swift             权限分发
│       ├── CategoryListView.swift     分类首页
│       ├── SwipeReviewView.swift      核心滑动审核
│       ├── PendingDeletionView.swift  待删除批量确认
│       └── Components/
│           ├── LiquidGlassCard.swift  液态玻璃容器（iOS 26 / 兼容）
│           └── PhotoCardView.swift    单张照片卡
├── scripts/build-ipa.sh               未签名 IPA 打包脚本
└── README.md
```

## 在模拟器运行

```bash
# 前置：Xcode 26+，并已安装 iOS Simulator runtime
xcrun simctl create "iPhone17Pro" "iPhone 17 Pro" "iOS26.5"
open -a Simulator
xcodebuild -project PhotoCleaner.xcodeproj -scheme PhotoCleaner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/PhotoCleaner.app
xcrun simctl launch booted com.maizhenying.PhotoCleaner
```

> 模拟器没有真实照片，启动后请通过 Safari 拖几张图到模拟器，或者从 Apple Mock Photos 添加。

## 打包未签名 IPA

```bash
bash scripts/build-ipa.sh
# 产物：build/PhotoCleaner.ipa
```

## 装入真机（无开发者账号）

未签名 IPA 不能直接安装。选一种工具用免费 Apple ID 自签后侧载，证书 7 天有效，到期需重签：

### 方案 A：Sideloadly（最简单，跨平台）

1. 下载 https://sideloadly.io
2. 用数据线连接 iPhone，电脑信任设备
3. 打开 Sideloadly，把 `build/PhotoCleaner.ipa` 拖进去
4. 输入你的免费 Apple ID（建议新建一个专用 ID）
5. 点 Start，等待安装完成
6. 在 iPhone「设置 → 通用 → VPN与设备管理」中信任该开发者证书
7. 主屏点开 PhotoCleaner

### 方案 B：AltStore（可后台续期）

1. 安装 AltStore：https://altstore.io（需要先装 AltServer 到 Mac）
2. 在 iPhone AltStore 中点「+」→ 选 `PhotoCleaner.ipa`
3. AltServer 在后台运行时会自动续期 7 天证书

### 方案 C：Xcode 直签（推荐，省事）

如果懒得用第三方工具，直接用 Xcode：

1. 用 Xcode 打开 `PhotoCleaner.xcodeproj`
2. 选中 PhotoCleaner target → Signing & Capabilities
3. Team 选「Add an Account…」用你的免费 Apple ID 登录
4. Bundle Identifier 改成全球唯一的字符串，例如 `com.<你的名字>.PhotoCleaner`
5. 数据线接 iPhone，顶部 destination 选你的设备
6. 按 ⌘R 运行，第一次需在 iPhone 设置里信任开发者证书

## 注意事项

- 免费 Apple ID 签发的证书 **每 7 天过期**，App 会停止启动，需要重新签名安装
- 免费证书 **每个 Apple ID 同时只能有 3 个 App** 装在设备上
- 删除操作会进入系统「最近删除」相册，30 天内可恢复，期间仍占用空间
- 「按应用分类」是基于元数据推断（分辨率、EXIF、媒体子类型），不是 100% 精确——iOS 系统层面不暴露照片来源 App

## 隐私

- 应用全部在本地处理，不上传任何照片或元数据
- 仅请求 `NSPhotoLibraryUsageDescription`（读写照片）
- 删除照片时由 iOS 系统弹原生确认对话框，应用无法绕过
