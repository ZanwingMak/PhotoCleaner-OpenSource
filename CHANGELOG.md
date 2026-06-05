# 更新日志

本项目遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。
版本号格式：MAJOR.MINOR.PATCH

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
