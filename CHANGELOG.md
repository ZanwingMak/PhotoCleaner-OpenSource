# 更新日志

本项目遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。
版本号格式：MAJOR.MINOR.PATCH

---

## [0.9.1] - 2026-06-06

### 新增
- **滑动审核交互式堆叠预览**：
  - 静止时只显示当前卡（不叠图，保持干净）
  - 拖拽开始时底层卡 fade in + 缩放（从 0.88 → 1.0），根据方向：
    - 左滑 / 上滑 → 显示**下一张**作为底层
    - 右滑 → 显示**前一张**作为底层
  - 拖得越远，底层卡越实（不透明度按距离 / 280 渐变到 1.0）
  - 离场动画期间也显示底层卡，让飞出的卡和下一张有视觉衔接
  - 上滑加入待删除时同样显示下一张做衔接

### 修复
- **主屏 AppIcon 不显示**：之前用散装 PNG 放在 .app 根目录 + Info.plist `CFBundleIcons.CFBundleIconFiles`
  数组的方式，被 iOS 13+ 弃用，SpringBoard 不识别 → 显示默认白色图标
- **改为 asset catalog 编译方案**（与 Xcode 标准流程一致）：
  - `Assets.xcassets/AppIcon.appiconset` 加入 1024 主图引用
  - `build-ipa.sh` 用 `xcrun actool` 编译 → 生成 `Assets.car`（含所有尺寸渲染）
  - actool 同时输出 partial.plist 含 `CFBundleIconName = "AppIcon"`，
    用 Python 合并进主 Info.plist（这是 iOS 14+ 主屏识别图标的关键 key）
  - simulator 版用 `--platform iphonesimulator`，真机版用 `--platform iphoneos` 分别编译
- 通过 `assetutil --info` 验证：Assets.car 内 AppIcon @phone @pad 两个 idiom 渲染齐全（397KB 主图 SHA1 28E216...）

---

## [0.9.0] - 2026-06-06

### 新增
- **Live Photo 支持**：检测 `PHAsset.mediaSubtypes.contains(.photoLive)`，
  用 `PHLivePhotoView`（封装为 SwiftUI 的 `LivePhotoView.swift`）渲染
  - `PhotoCardView`（滑动审核）：是 Live Photo 时显示 LivePhotoView，加载完后自动 hint 播放
  - `PhotoDetailView`（全屏大图）：Live Photo 长按播放（系统行为），其他照片支持缩放
  - 元数据胶囊上新增 **LIVE** 角标
- **`PhotoLibraryService.loadLivePhoto(for:targetSize:completion:)`** 新方法

### 修复
- **去掉照片卡的模糊放大底图**：之前 `PhotoCardView` 用同图 `.blur(radius: 40).opacity(0.55)`
  作为电影感外框，被吐槽「白金模糊背景」遮盖视觉；改为纯深色 `#0F0E0D` 背景，主图 `.scaledToFit` 居中

---

## [0.8.1] - 2026-06-06

### 修复
- **滑动审核页移除底层卡叠图**：之前用 `scale(0.93) + offset(y:18)` 露出底层卡顶部边缘营造堆叠感，
  仍能看到后面那张照片的内容；现在彻底移除 underlying card，每次只显示当前一张
  - 切换时用 `.transition(.opacity + .scale(0.95))` + `.animation(.easeInOut(0.22))` 做 fade 过渡
  - 删除未使用的 `underlyingAsset` / `previewNextAsset` / `previewPrevAsset` 计算属性

---

## [0.8.0] - 2026-06-06

### 新增
- **多语言支持**：中 / 英 / 日 / 韩 / 跟随系统，共 5 个选项
  - `LanguageManager` + `L10n` 字典管理所有 user-facing 字符串
  - 中文作为 key，提供英/日/韩译文
  - `@AppStorage` 持久化偏好，跟随系统时自动识别 `Locale.current.language.languageCode`
  - 设置里新增「语言」分组，横向 5 按钮选择，立即生效
- **README 多语言版本**：`README.md` 默认中文 +  `README.en.md` / `README.ja.md` / `README.ko.md`
  - 每个文件顶部带语言切换链接

### 修复
- **IPA 文件名包含版本号**：`build-ipa.sh` 自动从 CHANGELOG 顶部解析最新版本号，
  产物为 `PhotoCleaner-v0.8.0.ipa`，Info.plist 的 `CFBundleShortVersionString` 同步更新
- **照片大图页收藏按钮状态未即时刷新**：
  - 收藏 toggle 后立即更新 `@State isFavorite`（UI 即时变化）
  - `performChanges` 完成后 `assetsRefreshTick += 1` 触发重新 fetch PHAsset
  - 失败时回滚 state；切换照片时 `refreshFavoriteState()` 同步
  - 解决 `PHAsset` 不可变导致 `asset.isFavorite` 读取旧值的问题

### 变更
- 设置内显示版本号自动更新到 0.8.0
- `TabBarItem.rawValue` 直接作为 i18n key（中文）传给 `lm.t()`

---

## [0.7.0] - 2026-06-06

### 新增
- **`PhotoMetadataSheet`** 照片元数据详情 sheet（公用组件）
  - 大缩略图预览 + 文件名/尺寸/大小/类型/创建/修改/位置/时长/收藏 等完整信息
  - 「在 照片 App 中打开」按钮 → `photos-redirect://` URL Scheme
  - 「分享」按钮 → `UIActivityViewController`
- **`PhotoDetailView`** 全屏大图浏览（点击「照片」Tab 缩略图进入）
  - 左右滑翻页（TabView page style）
  - 单击隐藏/显示工具栏，双击 1x ↔ 2x 缩放
  - 捏合手势缩放（1~4 倍）+ 缩放后可拖拽平移
  - 底部药丸操作栏：收藏 / 分享 / Photos.app 跳转 / 详情
  - 顶部进度条「N / Total · 日期」
- **照片页筛选条**：顶部横向药丸 segmented (全部 / 收藏 / 视频 / 截图)，选中态品牌橙渐变
- **照片缩略图角标**：收藏 ❤︎ / 视频 / 截图 角标聚合在右下角
- **长按 ContextMenu**：查看大图 / 照片信息 / 在 照片 App 中打开
- **滑动审核左下角「信息」按钮**：第 4 个底部按钮，弹 `PhotoMetadataSheet`

### 修复
- **整理 / 相簿 顶部 tab 位置不一致**：把 greeting + segmented 抽离 ScrollView，
  作为固定顶栏，两个 tab 切换时顶部位置永远对齐
- **底部「更多」图标太小**：`ellipsis` 改为 `square.grid.2x2.fill`，
  与其他三个图标视觉重量一致；同步把所有 tab 图标统一改为 `.fill` 版本
- **重新扫描分类无反馈**：加 loading 状态（旋转转圈替换图标 + 文字「正在扫描…」），
  完成时弹绿色 toast「扫描完成 · N 张」 + 成功触觉反馈
- **滑动审核卡片堆叠透出背景**：底层卡 `opacity(0.6)` 去掉改为 100% 不透明，
  用 `scale(0.93) + offset(y:18)` 露出顶部边缘营造堆叠感

### 变更
- SwipeReviewView 底部按钮从 3 个变 4 个：信息 / 撤销 / 保留 / 删除

---

## [0.6.0] - 2026-06-06

### 新增
- **主题切换**：设置里新增「外观」分组
  - 5 个主题色块横向选择：跟随系统 / 默认深色 / 浅色 / 焦糖暖 / 冷色调
  - 选中态橙色描边 + 主题名加粗，触觉反馈
  - 偏好 `@AppStorage` 持久化，启动即生效
- **`ThemeManager`** 全局主题管理器，注入到 App 入口
- **`AppPalette` 主题感知 API**：`bgPrimary(for:)`/`bgCard(for:)`/`textPrimary(for:)` 等方法根据当前主题返回不同色值
- **滑动审核顶部分类切换**：点击顶部「分类名 ⌄」胶囊弹出 `CategoryPickerSheet`
  - 三个分组：快速合集 / 智能分类 / 系统相册
  - 当前分类高亮橙色 + ✓，点击切换无需返回首页
- **Tab Bar 高亮同步**：顶部「整理/相簿」切换时底部 tab bar 同步高亮

### 修复
- **底部 Tab Bar 液态玻璃增强**：
  - iOS 26 用 `.glassEffect.tint(brand.opacity(0.05))` 厚玻璃 + 品牌微光
  - 边缘高光渐变环 + 底部阴影遮罩，更立体
  - 选中 tab 改用品牌橙渐变胶囊 + 发光阴影
  - SF Symbol 切换时加 `.symbolEffect(.bounce)`
- **设置右上关闭按钮 2 层圆圈**：去掉 Button 自定义 Circle 背景，改用系统 ToolbarItem 文本按钮「关闭」
- **相簿列表整行可点**：`AlbumRow` 加 `.contentShape(Rectangle())`，Spacer 区域也响应点击
- **待删除缩略图 × 按钮被裁切**：用 ZStack + padding 6pt 给 × 留出空间，不再 offset 出界
- **第一张图按钮无法点击**：SwipeReviewView 重构为 ZStack overlay 结构，topBar/bottomBar `.zIndex(10)` 浮在卡片之上，永远可点
- **底部 tab bar 遮挡内容**：首页 ScrollView 底部 padding 从 90pt 增到 120pt

### 变更
- Tab Bar 图标更新：`integrate` 改为 `sparkles.rectangle.stack`，「更多」改为 `ellipsis`

---

## [0.5.0] - 2026-06-05

### 新增 — 补完功能闭环
- **照片浏览器（`PhotosBrowserView`）**：底部 Tab Bar 点「照片」打开
  - 3 列方形缩略图网格，2pt 间距，懒加载 + cancel
  - 视频右下角带 video 角标
  - 顶部「全部照片 · N」标题 + 左上 X 关闭
- **设置面板（`SettingsView`）**：右上齿轮或底部「更多」打开
  - 顶部品牌头：渐变 logo + PhotoCleaner 名称 + slogan
  - 三个分组：浏览体验（触觉/高清缩略图/二次确认开关）/ 数据（已扫描计数/重新扫描）/ 关于（版本/GitHub/反馈/更新日志）
  - 偏好用 `@AppStorage` 持久化
  - 暖橙圆形图标气泡 + 自定义深色 list 风格

### 修复
- **滑动审核空状态 bug**：之前 fetchAssets 返回空列表时永远显示 ProgressView，
  现在区分 `hasLoaded` 与 `assets.isEmpty`，空时显示「这个分类没有照片」+ 返回按钮

### 变更
- TabBar 行为接入实际功能：
  - 「照片」→ 弹 `PhotosBrowserView` sheet
  - 「更多」→ 弹 `SettingsView` sheet
  - 右上齿轮 → 弹 `SettingsView` sheet（与「更多」共用同一界面）

---

## [0.4.0] - 2026-06-05

### 新增 — 自有视觉语言
- **暖色深色主题**：纯黑改为深炭色 `#11100F`，右上角暖橙光晕 + 左下角粉红光晕，呼应 AppIcon
- **全局色板** `AppPalette`：品牌色（暖珊瑚 `#FF8C66`）、杏粉、文字三级灰度，统一调用
- **顶部问候**：按时段动态显示「早上好/下午好/晚上好/夜深了」 + 「PhotoCleaner」品牌字
- **Hero 卡片**：大字号「潜在可释放 X.X GB」+ 右侧环形进度条（已审核 N%）
- **智能建议横向卡**：两张大渐变卡引导用户先清「陈年截图」「占空间大户」，PhotoCleaner 特色
- **Bento Grid 不规则分类**：6 张分类卡用 2 列大小不一布局（170/130pt 高交错），右下角大装饰图标半透明
- **月份时间线**：竖向时间轴 + 圆点 + 连接线 + 数量条 + 月份标签，仿 git 提交墙
- **段控制改下划线版**：原药丸版改为下划线 + 文字，更轻量

### 新组件
- `Components/AppPalette.swift` — 全局色板
- `Components/RingProgress.swift` — 环形进度条（角度渐变 + 圆头）

### 变更
- `RootView` 启动时主动 `requestAuthorization`：TCC 已 grant 时不会再弹窗，直接进主界面
- `PhotoLibraryService` 新增 `refreshAuthorizationStatus()`，scenePhase 切到 active 时自动同步
- 段控制 tab 名「未整理」缩短为「整理」更简洁

---

## [0.3.0] - 2026-06-05

### 新增
- **AppIcon**：暖橙渐变背景 + 三张堆叠卡片 + 山形相片图案 + 右下角绿色对勾
  - 用 `scripts/generate-icon.swift` (CoreGraphics) 生成 1024x1024 主图
  - `build-ipa.sh` 自动用 `sips` 缩放成 iPhone/iPad 各尺寸（60/76/83.5/29/40 pt × 2x/3x）
  - Info.plist 自动注入 `CFBundleIcons` 和 `CFBundleIcons~ipad`
- **Toast 系统**：玻璃药丸式顶部浮现提示
  - `Components/ToastView.swift` + `.toast($binding)` 修饰器
  - 上滑加入待删除时弹「已加入待删除 · N」红色 toast
  - 占位 tab 点击弹「功能开发中」黄色 toast
  - 1.6 秒自动消失

### 变更
- **滑动方向再次修正**（最终对齐 iOS 标准照片浏览方向）：
  - **左滑** = 下一张（之前是前一张）
  - **右滑** = 前一张（之前是下一张）
  - 上滑 = 加入待删除（不变）
- 拖拽方向提示重新设计：取消粗描边矩形大字，改为轻量玻璃药丸（SF Symbol + 简短标签）
  - 左滑时屏幕左侧浮现「← 下一张」
  - 右滑时屏幕右侧浮现「前一张 →」
  - 上滑时屏幕顶部浮现红色「🗑 加入待删除」
  - iOS 26 使用 `.glassEffect`，iOS 17–25 降级 `.ultraThinMaterial`
- 浮动 Tab Bar 接入点击处理：
  - 「未整理」→ 切到首页未整理 segment
  - 「相簿」→ 切到首页相簿 segment
  - 「照片 / 更多」→ 弹「功能开发中」toast，0.6s 后回到「未整理」高亮

### 修复
- **X 关闭按钮无响应**：所有 Button 加 `.contentShape(Rectangle())` + `.buttonStyle(.plain)`
  明确 hit test 区域，配合 `.frame(44×44)` 满足 Apple HIG 触控目标尺寸
- **顶部 toolbar 元数据行 leading padding 优化**

---

## [0.2.0] - 2026-06-05

### 新增
- 首页完整重设计，仿 Slidebox 视觉：
  - 顶部「整理」大标题 + 黄色提示徽标
  - 「未整理 / 相簿」两段式 segmented control（药丸式）
  - 横向滚动的快速合集卡片（随机 / 本周 / 这一天 / 去年），各自带渐变色
  - 「最近」section 的 hero 卡（本周精选）
  - 灰色胶囊统计条（所有未整理 / 视频 / 截图）
  - 柔和粉彩月份分组胶囊（按月份循环 12 种 pastel 配色）
- 底部浮动药丸式 Tab Bar（未整理 / 照片 / 相簿 / 更多，液态玻璃）
- `MonthBucket` 数据模型 + `refreshCategoryCounts()` 自动聚合最近 24 个月
- 「相簿」Tab 列表视图（描边方框图标 + 名称 + 数量）

### 变更
- **滑动逻辑彻底重做**：从 Tinder 模式改为浏览翻页模式
  - 左滑 = 显示前一张
  - 右滑 = 显示下一张
  - 上滑 = 加入待删除并前进
- 滑动审核页顶部布局重设计：X 关闭 / 中央分类胶囊 / 垃圾桶 + badge
- 滑动审核页元数据条新增：进度 · 日期 · 时间（仿参考）
- 底部操作栏从「撤销/进度/上滑」改为「撤销/保留/删除」三按钮

### 修复
- 右上角垃圾桶 badge 被裁切的问题（之前用 `.offset` 推出 toolbar 边界，
  现在改为在 ZStack 内 padding 留位置，badge 自然落于角上不被裁切）
- 拖拽方向提示重新设计（前一张 / 下一张 / 加入待删除三方向标签）

### 新分类
- `PhotoCategory.quickPick(.random/.thisWeek/.onThisDay/.lastYear)` 快速合集
- `PhotoCategory.month(year:month:)` 按月份分组
- `InferredKind.allUnsorted / unsortedVideo` 用于灰色统计胶囊条

---

## [0.1.0] - 2026-06-05

### 新增
- 初始版本：基于 SwiftUI 的 iOS 26 照片整理应用
- 核心功能：
  - 读取系统照片库（含权限请求与拒绝引导）
  - 11 个分类入口（系统智能相册 + 元数据推断）
  - Tinder 式卡牌堆叠滑动审核
  - 待删除列表批量确认 + 系统原生确认对话框
  - 单步撤销
- iOS 26 液态玻璃 (`glassEffect`) + iOS 17 降级（`ultraThinMaterial`）
- 完整 Xcode 工程文件，可在 Xcode 直接打开
- 手工 swiftc 打包脚本（绕过 Xcode 26 simulator runtime 依赖）
- 未签名 IPA 输出 + Sideloadly/AltStore/Xcode 三种自签教程

### 已知限制
- 「按应用分类」基于元数据推断（PhotosKit 不暴露照片来源 App），不是 100% 精确
- 无 AppIcon（actool 在 Xcode 26 无 simulator runtime 时无法编译 asset catalog）
- 免费 Apple ID 自签证书 7 天过期

---

## 版本号规则

- **MAJOR**：不兼容的 API 变更或重大设计调整
- **MINOR**：向后兼容的新功能
- **PATCH**：向后兼容的 bug 修复

未发布的变更记入 `[Unreleased]`，发版时改为版本号 + 日期。
