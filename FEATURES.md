# 功能文档

PhotoCleaner 的功能规格说明。开发新功能或修改逻辑前先读这里。

---

## 1. 应用定位

一个 iOS 原生照片整理工具，目标用户是相册照片过多、想快速腾出存储空间的人。

**核心交互范式**：
- 浏览：左右滑动翻页
- 标记删除：上滑加入待删除列表
- 删除：批量确认后由系统弹原生对话框最终确认

---

## 2. 权限模型

### 2.1 必需权限
| Info.plist Key | 用途 |
|---|---|
| `NSPhotoLibraryUsageDescription` | 读取照片库进行分类与显示 |
| `NSPhotoLibraryAddUsageDescription` | 删除时可能用到（系统已自动处理） |

### 2.2 授权状态分发（RootView）
| 状态 | 视图 |
|---|---|
| `.notDetermined` | `PermissionView`（解释 + 「允许访问照片」按钮） |
| `.authorized` / `.limited` | `CategoryListView`（主界面） |
| `.denied` / `.restricted` | `PermissionDeniedView`（引导到系统设置） |

---

## 3. 分类系统

照片分类统一抽象为 `PhotoCategory` 枚举，共 5 种：

### 3.1 `.allPhotos` — 全部照片
直接 `PHAsset.fetchAssets(with:)` 返回所有资产。

### 3.2 `.quickPick(QuickPick)` — 快速合集
| Case | 算法 |
|---|---|
| `.random` | 全库 shuffle，取前 200 张 |
| `.thisWeek` | `creationDate` 与今天同周同年 |
| `.onThisDay` | 月日与今天相同（不限年份） |
| `.lastYear` | 创建年份 == 今年 - 1 |

### 3.3 `.smartAlbum(subtype:...)` — 系统智能相册
PhotosKit 原生支持：收藏、视频、实况照片、最近添加、截图等。

### 3.4 `.inferred(InferredKind)` — 元数据推断
| Case | 推断规则（PhotoClassifier.matches） |
|---|---|
| `.allUnsorted` | 全部（占位，用于统计） |
| `.unsortedVideo` | `mediaType == .video` |
| `.screenshot` | `mediaSubtypes.contains(.photoScreenshot)` |
| `.selfie` | 分辨率匹配前置摄像头典型尺寸 |
| `.camera` | 像素 >= 8MP 且非截图 |
| `.social` | 像素 < 2MP 且非截图（来自社交分享的压缩图） |
| `.landscape` | 宽 > 高 的图片 |
| `.portrait` | 高 > 宽 的图片 |
| `.largeFile` | 文件 > 5MB |

> ⚠️ **iOS 系统不暴露照片来源 App**，所以「按应用分类」只能用元数据弱推断，
> 不是 100% 准确。

### 3.5 `.month(year:month:)` — 按月份分组
`PhotoLibraryService.refreshCategoryCounts()` 时遍历所有资产按 `creationDate`
的年月分桶，按时间倒序取最近 24 个月。每个月份用 12 色循环的柔和粉彩。

---

## 4. 滑动审核

**手势规则**（位于 `SwipeReviewView.dragGesture`）：

| 手势 | 阈值 | 动作 |
|---|---|---|
| 手指向左拖 | `|h| > 100pt` 且 \|h\|>\|v\| | `SwipeAction.previous`（前一张） |
| 手指向右拖 | `h > 100pt` 且 \|h\|>\|v\| | `SwipeAction.next`（下一张） |
| 手指向上拖 | `v < -130pt` 且 \|v\|>\|h\| | `SwipeAction.markDelete`（加入待删除并前进） |
| 未达阈值 | — | 卡片回弹到中央 |

**视觉反馈**：
- 拖拽中：卡片跟随手指偏移 + 轻微旋转（仅水平方向，每 28pt 旋转 1°）
- 屏幕边缘出现方向标签（前一张 / 下一张 / 加入待删除）
- 释放后达到阈值：卡片飞出屏幕对应方向（左/右/上）
- 触觉反馈：导航 `.light`，删除 `.heavy`

**底部三按钮**（位于 `SwipeReviewView.bottomBar`）：
- **撤销**：等价于上一次 `markDelete` 操作的 undo（仅 markDelete 入 history）
- **保留**：等价于 `.next`
- **删除**：等价于 `.markDelete`

---

## 5. 待删除流程

### 5.1 数据模型
`SwipeReviewViewModel.pendingDeletion: [PHAsset]` 累积所有标记为待删除的资产。

### 5.2 用户界面
- 顶部 toolbar 右上角垃圾桶图标 + 红色数字 badge
- 点击进入 `PendingDeletionView`：网格预览所有待删除项
- 每张缩略图右上角有「×」可单独移除

### 5.3 最终删除
1. 用户点底部「确认删除」
2. App 弹应用自身的确认 alert（双重保险）
3. 用户确认后调用 `PHPhotoLibrary.performChanges { deleteAssets(...) }`
4. **iOS 系统弹原生确认对话框**（这是 PhotosKit 强制行为，App 无法绕过）
5. 用户在系统对话框点删除 → 真正进入「最近删除」相册（30 天可恢复）
6. App 同步更新本地状态（移除已删项、刷新计数、关闭 sheet）

---

## 6. 视觉系统

### 6.1 色彩
- 主背景：纯黑 `Color.black`
- 主文字：纯白
- 二级文字：白色 55% 不透明度
- 强调：黄色（提示徽标）、红色（删除）、绿色（导航/完成）

### 6.2 柔和粉彩月份配色（12 色循环）
| 月份 | 色相 |
|---|---|
| 1 月 | 冰蓝 |
| 2 月 | 嫩绿 |
| 3 月 | 米黄 |
| 4 月 | 蜜橙 |
| 5 月 | 樱粉 |
| 6 月 | 青绿 |
| 7 月 | 杏色 |
| 8 月 | 淡紫 |
| 9 月 | 珊瑚 |
| 10 月 | 抹茶 |
| 11 月 | 冰蓝 |
| 12 月 | 薰衣草 |

### 6.3 液态玻璃
- iOS 26+：使用原生 `.glassEffect(.regular, in: .capsule)` 修饰器
- iOS 17–25：降级为 `.ultraThinMaterial` + `.white.opacity(0.08)` 边框

### 6.4 字体
- 大标题：`.system(size: 34, weight: .bold)`
- section 标题：`.system(size: 22, weight: .bold)`
- 胶囊条：`.system(size: 17, weight: .semibold)`
- 元数据：`.system(size: 12, weight: .medium)`
- 全部使用系统默认字体（SF Pro）

### 6.5 触觉反馈触发点
| 操作 | 强度 |
|---|---|
| Tab 切换 | `.soft` |
| 撤销 | `.soft` |
| 翻页（左/右滑） | `.light` |
| 加入待删除（上滑） | `.heavy` |
| 移除待删除单项 | `.soft` |

---

## 7. 项目结构

```
PhotoCleaner/
├── PhotoCleanerApp.swift          应用入口
├── Info.plist                     权限声明
├── Models/
│   └── PhotoCategory.swift        分类枚举（5 大类）
├── Services/
│   ├── PhotoLibraryService.swift  PhotosKit 封装、月份聚合
│   └── PhotoClassifier.swift      元数据推断 + 快速合集筛选
├── ViewModels/
│   └── SwipeReviewViewModel.swift 翻页状态机 + 待删除队列 + undo
└── Views/
    ├── RootView.swift             授权状态分发
    ├── CategoryListView.swift     首页（仿 Slidebox 样式）
    ├── SwipeReviewView.swift      核心滑动审核页
    ├── PendingDeletionView.swift  待删除列表批量确认
    └── Components/
        ├── LiquidGlassCard.swift  液态玻璃容器
        ├── PhotoCardView.swift    单张照片卡片
        └── FloatingTabBar.swift   底部浮动药丸 Tab Bar
```

---

## 8. 兼容性与依赖

| 项 | 版本 |
|---|---|
| iOS Deployment Target | 17.0 |
| Swift | 5.0 |
| 第三方依赖 | 无 |
| 系统框架 | SwiftUI, Photos, UIKit (反馈) |

---

## 9. 未实现 / 已知限制

- [ ] 「相簿」Tab 仅展示推断分类，未接入用户自建相册
- [ ] 浮动 Tab Bar 仅一个 tab（整理）有功能，其它按钮当前为视觉占位
- [ ] 「随机」合集每次进入都重新洗牌（未持久化）
- [ ] hero「本周」卡片使用渐变占位图，未读取真实最新一张
- [ ] AppIcon 未配置
- [ ] 不支持 iPad 横屏布局优化
- [ ] 不支持深度链接 / Spotlight 搜索
- [ ] 删除时无文件大小预估精度优化（依赖 PHAssetResource）
