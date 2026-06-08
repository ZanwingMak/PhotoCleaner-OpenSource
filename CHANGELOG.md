# 更新日志

本项目遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。
版本号格式：MAJOR.MINOR.PATCH

---

## [1.1.2] - 2026-06-08

### 变更
- **「有 N 张待删除」弹窗精简为 3 个选项**：去掉「继续审核」，保留：
  - 查看待删除列表（主操作，蓝字）
  - 放弃并退出（destructive，红字）
  - 点错了（强调 cancel，**填充按钮**）
- **「点错了」按钮做强调样式** — 新增 `DialogAction.role = .highlightedCancel`：
  - 浅色主题：**蓝色填充背景 + 白字**
  - 深色主题：**白色填充背景 + 黑字**
  - 视觉权重最高，引导用户优先点击「点错了」取消误操作
- **弹窗背景跟随主题**：
  - 浅色：纯白卡片（清晰对比）
  - 深色：**液态玻璃**（`.glassEffect` 或 `.ultraThinMaterial`）

### 新增
- **首页刷新结束弹「刷新成功 · N 张」toast**：
  - 点击右上刷新按钮 → 完成弹 toast
  - 下拉刷新（unsortedScroll / albumsScroll）→ 完成弹 toast
  - 配合成功触觉反馈 `.notificationOccurred(.success)`
- L10n 新增「刷新成功 · %d 张」中英日韩翻译

---

## [1.1.1] - 2026-06-08

### 新增
- **`CustomDialog`** 自定义弹窗组件：替代 SwiftUI 系统 `confirmationDialog`
  - 宽度可控（max 360pt，比系统 alert 宽 33%）
  - 按钮颜色不受 app `.tint(brand)` 染色影响：
    - 主操作（查看待删除列表）：system blue (#007AFF)
    - 继续审核：system blue 普通
    - 放弃并退出：system red (#FF3B30) destructive
    - 点错了：system blue cancel 加粗
  - 半透明遮罩（点击关闭）+ 中心卡片（白底深字 / 深底白字 主题自适应）+ 阴影 + 缩放转场
  - `.customDialog(isPresented:title:message:actions:)` View 修饰器调用

### 修复
- **「跟随系统」语言选项未翻译**：SettingsView 内 `Text(lm.current.title)` 和 `Text(lang.title)` 都没用 `lm.t()` 包装
  - 现在每个 lang.title 都走 L10n 字典翻译，英文显示 "System"，日语「システム」，韩语「시스템」

### 变更
- 「有 N 张待删除」弹窗换用 `customDialog`，宽度更宽 + 颜色更清晰

---

## [1.1.0] - 2026-06-08

第二个稳定版本，主题系统重做，bug 全面修复。

### 修复
- **「有 N 张待删除」弹窗** 加回「点错了」cancel 选项
  - 三个动作：查看待删除列表 / 继续审核 / 放弃并退出
  - 加一个 cancel 选项「点错了」让误触能取消
- **焦糖暖 / 冷色调主题不全局生效**：CategoryListView 的 backgroundLayer / heroStorageCard / BentoCard 全部改用 `AppPalette.xxx(for: themeManager.current)`
  - 焦糖暖：深褐色背景 + 暖橙强调
  - 冷色调：深蓝灰背景 + 暖橙强调
- **底部 tab bar 关闭 sheet 后高亮回到「整理」**：之前点 photos / more 时强制设 `tabBarItem = .more / .photos` 然后 0.4s 后强制回 `.organize` 覆盖了原 segmented 状态
  - 现在点 photos / more 只触发 sheet，**不改变 tabBarItem**
  - 关闭 sheet 后高亮保持在原 tab（整理 / 相簿）

### 新增
- `BentoCard` 加 `@EnvironmentObject themeManager` 注入，所有分类卡跟随主题
- L10n 字典新增「点错了」key（中英日韩四语）

### 默认值确认
- 默认主题：**深色**（`AppStorage("app_theme") default = .dark.rawValue`）
- 默认语言：**跟随系统**

---

## [1.0.3] - 2026-06-08

### 修复
- **「有 N 张待删除」弹窗 1/3 选项颜色看不清** — Alert 改用 `confirmationDialog` (action sheet 风格)
  - iOS 系统对比度高，三个选项（查看待删除列表 / 放弃并退出 / 继续审核）都鲜亮
  - 顺序优化：主操作放最上面，destructive 用红色，cancel 放底部
- **设置 / 待删除 / 照片浏览 / 元数据 / 分类切换 sheet 不响应主题切换** — 显式声明 `.preferredColorScheme(themeManager.current.colorScheme)` 在每个 sheet view
  - iOS Sheet 不自动继承 parent 的 preferredColorScheme，必须每个 sheet 单独设
  - 5 个 sheet 全部加 `@EnvironmentObject themeManager`
- **浅色主题下底部 FloatingTabBar 看不清** — 未选中态文字色用 `Color.secondary`（系统自动适配）
  - 浅色：灰色 60%
  - 深色：白色 60%
  - 选中态保留白色（彩色 brand 渐变 bg 上）
  - 边框 / 高光 / 阴影都改用 `Color.primary.opacity(...)` 浅色下也可见
- **深色文字看不清** — `Color.white.opacity(装饰)` 全面替换为 `Color.primary.opacity(...)`
  - 自动跟 ColorScheme：light 下变浅灰，dark 下变浅白

---

## [1.0.2] - 2026-06-07

### 修复
- **主题切换不全局生效** — AppPalette 静态属性改用 `UIColor` `dynamicProvider`，自动跟随 ColorScheme（light / dark）切换
  - bgPrimary / bgCard / bgCardElevated / textPrimary / textSecondary / textTertiary 全部双色
  - 视图层去掉强制 `.preferredColorScheme(.dark)`（首页 / 设置 / 待删除 / 照片浏览 / 元数据 5 个视图），改为跟随 RootView 全局 `themeManager.current.colorScheme` 设置
  - 图片浏览类（SwipeReviewView / PhotoDetailView）保留 dark
- **浅色模式文字看不清** — 所有装饰用的 `Color.white.opacity(0.05~0.12)` 替换为 `Color.primary.opacity(...)`
  - AlbumRow 分隔线 / 段控制未选中态 / 按钮背景 / 描边
  - 浅色下变浅灰，深色下变浅白，两边都清晰可见
- **「有 N 张待删除」alert 看不清** — 跟随主题动态色，去掉强制 dark 后系统 alert 自动适配
- **Toast 提示浅色看不清** — `ToastView` 改用 `@Environment(\.colorScheme)`
  - light: 白底（0.95 opacity） + 黑字 + 黑色描边
  - dark: 深底（0.75 opacity） + 白字 + 白色描边
- **首页刷新按钮点击无即时反馈** — 点击瞬间立即用 `easeOut 0.6s` 转 360°；isLoading 期间 Timer 继续累加

---

## [1.0.1] - 2026-06-07

### 修复
- **滑动切换照片时闪烁** — 新增全局 `ThumbnailCache` (NSCache 限 300 项)
  - `PhotoCardView.init(asset:)` 立即从缓存取 image 作为 @State 初始值
  - `load` 时若 image 已非 nil 跳过请求；不再 withAnimation 赋值（静默）
- **待删除缩略图重叠** — 改用 `Color.clear + aspectRatio(1) + GeometryReader` 强制每个 cell 严格 side×side
  - image 显式 `.frame(width: side, height: side)` + `.clipped()` 不再溢出
- **刷新按钮无持续动画** — 改用 Timer 每 0.6s 累加 360° 旋转，配 `.animation(.linear(duration:0.6))`
  - 加载结束时角度保留在最后位置，自然停下不回弹
- **每张图的边框 + 外阴影** — `PhotoCardView` 去掉 `.strokeBorder` 和 `.shadow`，照片不再有"画框感"

---

## [1.0.0] - 2026-06-07

第一个正式版本。

### 新增
- **抽卡牌动画**：滑动审核页改用 2D 变换（rotateZ + scale + offset）替代 3D rotation，60fps 流畅
  - 当前卡：跟手指走 + rotateZ ±15°（按手指偏移 / 24）+ 轻微缩小
  - prev/next：从 ±0.5w 滑到中心，scale 0.88→1，rotation ±8°→0°
  - 锚点 `.bottom` 让倾斜以底边为轴，更像真实抽卡
- **退出 / 切换分类确认弹窗**：当 `pendingDeletion` 非空时
  - 点 X 关闭 / 切换分类不会立刻退出
  - 弹三选项 alert：「查看待删除列表 / 继续审核 / 放弃并退出」
- **首页刷新按钮**：右上角加 `arrow.clockwise` 按钮，加载时图标旋转动画
- **首页下拉刷新**：unsortedScroll / albumsScroll 都加 `.refreshable` 修饰器，原生 Safari 风手势
- **GPL v3 LICENSE**：仓库根目录加完整 GNU GPL v3 文本

### 修复
- **双重切换动画**：trigger 重构为「spring 推进 dragOffset 到屏外 + 静默切换 vm.currentIndex」
  - 用 `Transaction.disablesAnimations = true` 包住 vm.handle，避免 SwiftUI 切换 id 时再触发一次动画
  - 移除 `exitDirection` 状态变量，单 dragOffset 驱动一切
- **元数据胶囊抖动**：把 PhotoCardView 内部的元数据胶囊移到 SwipeReviewView 固定层
  - `.transaction { $0.animation = nil }` 显式禁用滑动期间的动画
  - 改用半透明深底 (`Color.black.opacity(0.55)`) + 白字 + 白色描边，浅色/深色主题都清晰
- **待删除列表缩略图重叠**：grid 从 `.adaptive(minimum:100, maximum:140)` 改为固定 3 列 `.flexible()`
  - 缩略图加 `.aspectRatio(1, contentMode: .fit) + .clipped()`，每张严格 1:1

### 文档
- 4 个 README（中/英/日/韩）license badge 从 MIT 改为 GPL-3.0
- CHANGELOG 完整记录 0.1.0 → 1.0.0 每个版本

---

## [0.9.5] - 2026-06-07

### 修复
- **滑动审核预览前后图片错位**：之前 PhotoCardView 在 prev/next 位置没加 `.id()`，
  当 currentIndex 切换时 SwiftUI 复用了旧的 view（包括 `@State image`），
  导致预览看到的是「自己/上一次的图片」而不是真正的前/后一张。
  现在 prev/next 各加 `.id("prev-<localId>")` / `.id("next-<localId>")` 强制重建。

---

## [0.9.4] - 2026-06-07

### 修复
- **设置版本号动态读取**：之前硬编码 "0.8.0"，现在从 `Bundle.main.infoDictionary["CFBundleShortVersionString"]` 读取，跟随每次 build-ipa.sh 自动更新
- **照片/相簿/设置 i18n 完整覆盖**：
  - SettingsView：brand 副标 / 「主题」标签 / themeSwatch 内每个主题名 / 「正在扫描…」/「重新扫描分类」/ 扫描完成 toast / 底部隐私声明
  - CategoryListView：「潜在可释放」/「基于 N 张照片估算」/ SuggestionCard 「张」/ QuickPickCard 标题+「张」/ BentoCard 标题+「张」/ AlbumRow 分类名 / TimelineRow 月份
- **月份本地化**：TimelineRow 改用 `DateFormatter.setLocalizedDateFormatFromTemplate("MMM")` + `lm.effective.localeIdentifier`，自动出 "Jun"/"6月"/"6월"
- **元数据日期本地化**：SwipeReviewView / PhotoMetadataSheet / PhotoDetailView 三处 DateFormatter 全部去掉硬编码 "yyyy年M月d日"，改 `setLocalizedDateFormatFromTemplate("yMMMdHm")`

### 新增
- `AppLanguage.localeIdentifier` 属性：用于 DateFormatter / NumberFormatter 等 system 格式化
- L10n 字典补「张」「%d 月」「整理你的照片库，腾出存储空间」等约 10 个新 key

---

## [0.9.3] - 2026-06-06

### 新增
- **待删除列表多选**：进入时默认全选，每张缩略图右上角圆形选中指示器
  - 单击切换选中态（橙色品牌色描边 + 半透明覆盖 + 对勾）
  - 顶部右上「全选 / 全不选」一键切换
  - 底部「确认删除」只删选中的，未选保留在 pendingDeletion 队列
  - 已选数量同步在底部「可释放 · N」显示

- **L10n 字典扩充约 30 个新 key**：补全待删除多选/权限页/空状态/toast/扫描提示等场景

### 修复
- **Coverflow 方向校准**：之前左滑时下一张错误从**左边**过来
  - 修正 `swipeProgress` 公式（去掉负号）
  - 现在左滑：下一张从**右边**推入；右滑：前一张从**左边**推入（符合 iOS Photos 标准方向）
  - 当前卡反向倾斜让位（左滑时翻向右侧 +35°，让 next 露出）

- **拖动时立即看到前/后图片**：opacity 起步速度 ×5
  - 拖约 72pt（屏宽 1/5）就完全显现，不必等到滑动结束才看到

- **i18n 覆盖大幅补全**：
  - SwipeReviewView：分类胶囊 / 方向标签 / 4 个底部按钮 / 空态 / 完成态 / toast / CategoryPickerSheet
  - PhotosBrowserView：标题 / 筛选条 / 长按菜单 / 空态
  - PhotoMetadataSheet：所有元数据 row 标签 + 媒体类型 + 操作按钮
  - PendingDeletionView：标题 / 多选按钮 / 空态 / 确认 alert
  - RootView：权限引导文案 + 拒绝引导

---

## [0.9.2] - 2026-06-06

### 新增
- **滑动审核 Coverflow 3D 动画**（仿 swiper.js Effect Coverflow）：
  - 静止时只显示当前卡，纯净不叠
  - 拖动开始时**前一张从左侧 / 下一张从右侧** 3D 倾斜跟随手指过来
  - 三轴变换同步进行：
    - **rotation3DEffect(axis: Y, perspective: 0.8)** — 左右卡 ±45° 倾斜，朝中心翻正
    - **scale 0.82 → 1.0** — 进入中心时放大到正常
    - **offset 0.55w → 0** — 从屏幕外 X 位置回到中心
    - **opacity 0 → 1** — 静止隐藏，拖动渐显
  - 当前卡同步反向旋转 ±35° + 缩小 12%，强化"翻页"立体感
  - `swipeProgress` 计算属性把 dragOffset 归一化到 -1 ~ +1，三张卡所有参数都由它驱动
- 上滑（删除）时自动隐藏左右 coverflow 卡，让当前卡向上飞出，无杂乱

### 修复（接 v0.9.1）
- `PhotoCardView` 加载完照片后**不再绘制不透明背景** —— 静态深色 `Color` 仅在 loading 中显示
  让堆叠层之间相互可见，coverflow 动画立体感更清晰

### 清理
- 移除已不再使用的 `underlyingAsset` / `underlyingScale` / `underlyingOpacity` / `underlyingOffset` /
  `rotationAngle` 等 v0.9.0/v0.9.1 的过渡实现

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
