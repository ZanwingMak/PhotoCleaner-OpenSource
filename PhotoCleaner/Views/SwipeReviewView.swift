//
//  SwipeReviewView.swift
//  滑动审核：左滑下一张 / 右滑前一张 / 上滑加入待删除（iOS 标准浏览方向）
//

import SwiftUI
import Photos

/// 顶部胶囊点击后弹出的分类选择 sheet
struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lm: LanguageManager
    let currentId: String
    let onPick: (PhotoCategory) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        section(lm.t("快速合集")) {
                            ForEach(PhotoCategory.quickPicks) { cat in
                                row(cat)
                            }
                        }
                        section(lm.t("智能分类")) {
                            ForEach(PhotoCategory.InferredKind.allCases, id: \.self) { kind in
                                row(.inferred(kind))
                            }
                        }
                        section(lm.t("系统相册")) {
                            row(.allPhotos)
                            row(.smartAlbum(.smartAlbumFavorites, title: "收藏",
                                            symbol: "heart.fill", tint: .red))
                            row(.smartAlbum(.smartAlbumVideos, title: "视频",
                                            symbol: "video.fill", tint: .green))
                            row(.smartAlbum(.smartAlbumRecentlyAdded, title: "最近添加",
                                            symbol: "clock.fill", tint: .yellow))
                        }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            
            .navigationTitle(lm.t("切换分类"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lm.t("关闭")) { dismiss() }.tint(AppPalette.brand)
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppPalette.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 4) {
                content()
            }
        }
    }

    /// 单个分类行
    private func row(_ cat: PhotoCategory) -> some View {
        let selected = (cat.id == currentId)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onPick(cat)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(cat.tint.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: cat.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(cat.tint)
                }
                Text(lm.t(cat.title))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppPalette.brand)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AppPalette.brand.opacity(0.12)
                                   : AppPalette.bgCard)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SwipeReviewView: View {
    let category: PhotoCategory
    @EnvironmentObject private var library: PhotoLibraryService
    @EnvironmentObject private var lm: LanguageManager
    @StateObject private var vm: SwipeReviewViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGSize = .zero
    @State private var showPendingSheet = false
    @State private var toast: ToastInfo?
    @State private var hasLoaded = false
    @State private var showCategoryPicker = false
    @State private var showMetadata = false
    @State private var currentCategory: PhotoCategory

    /// 退出/切换时待处理的目标：dismiss 或切换到某分类
    @State private var pendingExitConfirm: PendingExitAction? = nil

    enum PendingExitAction: Equatable {
        case dismiss
        case switchCategory(PhotoCategory)

        static func == (lhs: PendingExitAction, rhs: PendingExitAction) -> Bool {
            switch (lhs, rhs) {
            case (.dismiss, .dismiss): return true
            case let (.switchCategory(a), .switchCategory(b)): return a.id == b.id
            default: return false
            }
        }
    }

    enum ExitDirection { case none, left, right, up }

    init(category: PhotoCategory) {
        self.category = category
        _currentCategory = State(initialValue: category)
        _vm = StateObject(wrappedValue: SwipeReviewViewModel(assets: []))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 中间内容层：卡片或状态视图，给 toolbar 留出 inset
            GeometryReader { geo in
                ZStack {
                    if !hasLoaded {
                        ProgressView().tint(.white)
                    } else if vm.assets.isEmpty {
                        emptyState
                    } else if !vm.hasMore {
                        finishedState
                    } else {
                        cardArea(in: CGSize(width: geo.size.width,
                                            height: geo.size.height - 196))
                        directionOverlay(in: geo.size)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .padding(.top, 96)    // 给 topBar + metaLine 留空间
            .padding(.bottom, 100) // 给 bottomBar 留空间

            // 顶部 overlay：用 zIndex 强制在卡片之上
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                metaLine
                    .padding(.top, 6)
                Spacer()
            }
            .zIndex(10)

            // 元数据胶囊（固定层，不随卡片动画飞）
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    metaPillFixed
                        .transaction { $0.animation = nil } // 切换 asset 时不带动画
                        .id(vm.currentAsset?.localIdentifier ?? "none")
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 110) // 在底部按钮之上
            }
            .zIndex(9)
            .allowsHitTesting(false)

            // 底部 overlay
            VStack(spacing: 0) {
                Spacer()
                bottomBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .zIndex(10)
        }
        .toast($toast)
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPendingSheet) {
            PendingDeletionView(vm: vm)
        }
        .sheet(isPresented: $showMetadata) {
            if let asset = vm.currentAsset {
                PhotoMetadataSheet(asset: asset)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(currentId: currentCategory.id) { newCategory in
                // 切分类前检查待删除
                if vm.pendingDeletion.isEmpty {
                    switchCategory(to: newCategory)
                } else {
                    showCategoryPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        pendingExitConfirm = .switchCategory(newCategory)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(String(format: lm.t("有 %d 张待删除"), vm.pendingDeletion.count),
               isPresented: Binding(
                get: { pendingExitConfirm != nil },
                set: { if !$0 { pendingExitConfirm = nil } }
               )) {
            Button(lm.t("查看待删除列表")) {
                showPendingSheet = true
                pendingExitConfirm = nil
            }
            Button(lm.t("继续审核"), role: .cancel) {
                pendingExitConfirm = nil
            }
            Button(lm.t("放弃并退出"), role: .destructive) {
                let action = pendingExitConfirm
                vm.pendingDeletion.removeAll()
                vm.deleteHistory.removeAll()
                pendingExitConfirm = nil
                switch action {
                case .dismiss?:
                    dismiss()
                case .switchCategory(let cat)?:
                    switchCategory(to: cat)
                case nil: break
                }
            }
        } message: {
            Text(lm.t("有待删除的照片未处理。继续退出会清空当前选择。"))
        }
        .task {
            await loadAssets(for: currentCategory)
        }
    }

    /// 切换分类：清空 VM 状态，重新加载
    private func switchCategory(to newCategory: PhotoCategory) {
        currentCategory = newCategory
        hasLoaded = false
        vm.assets = []
        vm.currentIndex = 0
        vm.pendingDeletion = []
        vm.deleteHistory = []
        showCategoryPicker = false
        Task { await loadAssets(for: newCategory) }
    }

    private func loadAssets(for cat: PhotoCategory) async {
        let assets = library.fetchAssets(for: cat)
        vm.assets = assets
        hasLoaded = true
    }

    // MARK: - 顶部三件套

    private var topBar: some View {
        HStack(spacing: 0) {
            // X 关闭：明确 contentShape 确保整个 frame 可点
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if vm.pendingDeletion.isEmpty {
                    dismiss()
                } else {
                    pendingExitConfirm = .dismiss
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 中央胶囊：点击弹出分类选择 sheet
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                showCategoryPicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(lm.t(currentCategory.title))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    Capsule().fill(Color.white.opacity(0.12))
                }
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            // 垃圾桶 + badge
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPendingSheet = true
            } label: {
                trashWithBadge
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// 垃圾桶 + 内嵌不裁切的红色 badge
    private var trashWithBadge: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "trash")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .padding(.top, 8)
                .padding(.trailing, 4)

            if !vm.pendingDeletion.isEmpty {
                Text("\(vm.pendingDeletion.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .padding(.horizontal, 3)
                    .background(Capsule().fill(.red))
                    .overlay(Capsule().strokeBorder(.black, lineWidth: 1.5))
            }
        }
    }

    // MARK: - 元数据行

    private var metaLine: some View {
        Group {
            if let asset = vm.currentAsset {
                let date = asset.creationDate ?? Date()
                HStack(spacing: 8) {
                    Text("\(vm.currentIndex + 1) / \(vm.assets.count)")
                    Text("·")
                    Text(formatMetaDate(date))
                    Text("·")
                    Text(formatMetaTime(date))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
            } else {
                Color.clear.frame(height: 14)
            }
        }
    }

    /// 固定层的元数据胶囊：不随卡片飞，深底白字保证浅/暗主题都清晰
    @ViewBuilder
    private var metaPillFixed: some View {
        if let asset = vm.currentAsset {
            let sizeStr = ByteCountFormatter.string(
                fromByteCount: PhotoClassifier.estimatedSize(of: asset),
                countStyle: .file)
            let dim = "\(asset.pixelWidth)×\(asset.pixelHeight)"
            let isLive = asset.mediaSubtypes.contains(.photoLive)
            let typeIcon: String = {
                if asset.mediaType == .video { return "video.fill" }
                if isLive { return "livephoto" }
                return "photo.fill"
            }()

            HStack(spacing: 6) {
                Image(systemName: typeIcon)
                    .font(.system(size: 11, weight: .bold))
                if isLive {
                    Text("LIVE")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Capsule().fill(.white.opacity(0.22)))
                }
                Text(dim)
                    .font(.system(size: 12, weight: .medium))
                Text("·").font(.system(size: 12)).opacity(0.6)
                Text(sizeStr)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(Color.black.opacity(0.55))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1))
            )
        }
    }

    /// 元数据日期本地化（按当前语言）
    private func formatMetaDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: lm.effective.localeIdentifier)
        f.setLocalizedDateFormatFromTemplate("yMMMd")
        return f.string(from: date)
    }

    private func formatMetaTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: lm.effective.localeIdentifier)
        f.setLocalizedDateFormatFromTemplate("Hm")
        return f.string(from: date)
    }

    // MARK: - 卡片区域

    private func cardArea(in size: CGSize) -> some View {
        ZStack {
            // Coverflow：前一张从左侧 3D 倾斜跟过来，下一张从右侧 3D 倾斜跟过来
            // 上滑（删除）时隐藏左右堆叠卡，让当前卡向上飞出

            // 抽卡牌动画：纯 2D 变换（rotateZ + scale + offset），60fps 流畅
            // prev 在左侧倾斜堆叠，next 在右侧倾斜堆叠，静止 opacity 0
            // 共享 asset.localIdentifier 作 id，让 SwiftUI 在切换时识别 next→current 是同一 view，自动 morph

            if let prev = prevAsset {
                PhotoCardView(asset: prev)
                    .scaleEffect(prevScale)
                    .offset(x: prevOffsetX(in: size))
                    .rotationEffect(.degrees(prevRotationZ), anchor: .bottom)
                    .opacity(isVerticalDrag ? 0 : prevOpacity)
                    .allowsHitTesting(false)
                    .zIndex(1)
                    .id(prev.localIdentifier)
            }

            if let next = nextAsset {
                PhotoCardView(asset: next)
                    .scaleEffect(nextScale)
                    .offset(x: nextOffsetX(in: size))
                    .rotationEffect(.degrees(nextRotationZ), anchor: .bottom)
                    .opacity(isVerticalDrag ? 0 : nextOpacity)
                    .allowsHitTesting(false)
                    .zIndex(1)
                    .id(next.localIdentifier)
            }

            if let asset = vm.currentAsset {
                PhotoCardView(asset: asset)
                    .scaleEffect(currentScale)
                    .offset(currentCardOffset)
                    .rotationEffect(.degrees(currentRotationZ), anchor: .bottom)
                    .gesture(dragGesture(in: size))
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: dragOffset)
                    .zIndex(10)
                    .id(asset.localIdentifier)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: vm.currentIndex)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Coverflow 参数

    /// 拖拽水平进度（直观映射）：
    ///   progress < 0  = 左滑   = 下一张 next 从**右侧**推过来
    ///   progress > 0  = 右滑   = 前一张 prev 从**左侧**推过来
    private var swipeProgress: CGFloat {
        let p = dragOffset.width / 360.0
        return max(-1, min(1, p))
    }

    /// 是否主要在做垂直拖（上滑删除场景，隐藏左右 coverflow 卡）
    private var isVerticalDrag: Bool {
        abs(dragOffset.height) > abs(dragOffset.width) && dragOffset.height < -20
    }

    private var prevAsset: PHAsset? {
        let i = vm.currentIndex - 1
        guard i >= 0 else { return nil }
        return vm.assets[i]
    }

    private var nextAsset: PHAsset? {
        let i = vm.currentIndex + 1
        guard i < vm.assets.count else { return nil }
        return vm.assets[i]
    }

    /// 当前卡缩放：拖远稍微缩小（让位给新卡）
    private var currentScale: CGFloat {
        return 1 - abs(swipeProgress) * 0.05
    }

    /// 当前卡 Z 轴旋转（抽卡牌感）：左滑朝右倾，右滑朝左倾，仿真实抽出
    private var currentRotationZ: Double {
        // dragOffset.width 直接驱动，比 swipeProgress 更跟手
        return Double(dragOffset.width / 24)
    }

    // 显现速度系数：拖动 1/5 进度（约 72pt）就完全不透明
    private static let opacityBoost: Double = 5

    /// 前一张 X 偏移：静止 -0.5w（左外），右滑到 +1 时到中心
    private func prevOffsetX(in size: CGSize) -> CGFloat {
        let restX = -size.width * 0.5
        return restX * (1 - max(0, swipeProgress))
    }

    private var prevScale: CGFloat {
        0.88 + max(0, swipeProgress) * 0.12
    }

    /// 前一张 Z 轴静止 -8° 倾斜，到中心时 0°
    private var prevRotationZ: Double {
        Double(-8 + max(0, swipeProgress) * 8)
    }

    private var prevOpacity: Double {
        min(1.0, max(0, Double(swipeProgress)) * Self.opacityBoost)
    }

    /// 下一张 X 偏移：静止 +0.5w（右外）→ 中心
    private func nextOffsetX(in size: CGSize) -> CGFloat {
        let restX = size.width * 0.5
        return restX * (1 - max(0, -swipeProgress))
    }

    private var nextScale: CGFloat {
        0.88 + max(0, -swipeProgress) * 0.12
    }

    /// 下一张 Z 轴静止 +8° 倾斜，到中心时 0°
    private var nextRotationZ: Double {
        Double(8 - max(0, -swipeProgress) * 8)
    }

    private var nextOpacity: Double {
        min(1.0, max(0, Double(-swipeProgress)) * Self.opacityBoost)
    }

    /// 当前卡 offset = dragOffset 自身，trigger 通过 animate dragOffset 推到屏外
    /// 不再用 exitDirection 单独控制
    private var currentCardOffset: CGSize {
        return dragOffset
    }

    // MARK: - 拖拽手势（iOS 标准方向）

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let h = value.translation.width
                let v = value.translation.height
                let hThreshold: CGFloat = 100
                let upThreshold: CGFloat = -130

                // 上滑优先
                if v < upThreshold && abs(v) > abs(h) {
                    trigger(.markDelete, direction: .up)
                    return
                }
                // 左滑（手指向左）→ 下一张（标准方向）
                if h < -hThreshold {
                    if vm.canGoNext {
                        trigger(.next, direction: .left)
                    } else {
                        dragOffset = .zero
                    }
                    return
                }
                // 右滑（手指向右）→ 前一张
                if h > hThreshold {
                    if vm.canGoPrevious {
                        trigger(.previous, direction: .right)
                    } else {
                        dragOffset = .zero
                    }
                    return
                }
                dragOffset = .zero
            }
    }

    /// 触发动作：spring 推进 dragOffset → coverflow 自然完成 → 静默切换数据
    /// 不再用 exitDirection 触发双重动画
    private func trigger(_ action: SwipeAction, direction: ExitDirection) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle = (action == .markDelete) ? .heavy : .light
        UIImpactFeedbackGenerator(style: style).impactOccurred()

        // 推进 dragOffset 到屏幕外，coverflow 各卡跟随到目标位置
        let target: CGSize
        switch direction {
        case .left:  target = CGSize(width: -800, height: 0)
        case .right: target = CGSize(width: 800, height: 0)
        case .up:    target = CGSize(width: 0, height: -1200)
        case .none:  return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            dragOffset = target
        }

        // 动画完成后静默切换数据 + reset dragOffset（无回弹动画）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                vm.handle(action)
                dragOffset = .zero
            }

            // markDelete 触发 toast
            if action == .markDelete {
                let template = lm.t("已加入待删除 · %d")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    toast = ToastInfo(
                        symbol: "trash.fill",
                        text: String(format: template, vm.pendingDeletion.count),
                        tint: .red
                    )
                }
            }
        }
    }

    // MARK: - 拖拽方向提示（轻量玻璃药丸版）

    private func directionOverlay(in size: CGSize) -> some View {
        ZStack {
            // 左滑 → 下一张：右侧出现小箭头玻璃片
            if dragOffset.width < -30 && dragOffset.height > -60 {
                arrowChip(symbol: "arrow.left", label: lm.t("下一张"), tint: .white)
                    .opacity(min(1, abs(dragOffset.width) / 100))
                    .scaleEffect(0.9 + min(0.2, abs(dragOffset.width) / 500))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
            }
            // 右滑 → 前一张：左侧出现小箭头玻璃片
            if dragOffset.width > 30 && dragOffset.height > -60 {
                arrowChip(symbol: "arrow.right", label: lm.t("前一张"), tint: .white)
                    .opacity(min(1, abs(dragOffset.width) / 100))
                    .scaleEffect(0.9 + min(0.2, abs(dragOffset.width) / 500))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
            }
            // 上滑 → 加入待删除：屏幕顶部红色玻璃片
            if dragOffset.height < -30 {
                arrowChip(symbol: "trash.fill", label: lm.t("加入待删除"), tint: .red)
                    .opacity(min(1, abs(dragOffset.height) / 130))
                    .scaleEffect(0.9 + min(0.2, abs(dragOffset.height) / 600))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 12)
            }
        }
        .allowsHitTesting(false)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset == .zero)
    }

    /// 玻璃药丸：图标 + 标签
    private func arrowChip(symbol: String, label: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            if #available(iOS 26.0, *) {
                Capsule().fill(.clear)
                    .glassEffect(.regular.tint(tint.opacity(tint == .red ? 0.35 : 0.0)), in: .capsule)
            } else {
                Capsule().fill(.ultraThinMaterial)
                    .overlay {
                        Capsule().fill(tint.opacity(tint == .red ? 0.25 : 0.05))
                    }
                    .overlay {
                        Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    }
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 6)
    }

    // MARK: - 底部三按钮

    private var bottomBar: some View {
        HStack {
            // 左下：信息按钮（弹元数据 sheet）
            actionButton(symbol: "info.circle", title: lm.t("信息"), color: .white,
                         disabled: vm.currentAsset == nil) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showMetadata = true
            }

            Spacer()

            actionButton(symbol: "arrow.uturn.backward", title: lm.t("撤销"), color: .white,
                         disabled: vm.deleteHistory.isEmpty) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                vm.undoLastDelete()
            }

            Spacer()

            actionButton(symbol: "arrow.down", title: lm.t("保留"), color: .white,
                         disabled: !vm.hasMore) {
                if vm.canGoNext {
                    trigger(.next, direction: .left)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            Spacer()

            actionButton(symbol: "xmark", title: lm.t("删除"), color: .red,
                         disabled: !vm.hasMore) {
                trigger(.markDelete, direction: .up)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func actionButton(symbol: String, title: String, color: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .strokeBorder(color.opacity(disabled ? 0.3 : 0.8), lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(color.opacity(disabled ? 0.3 : 1))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color.opacity(disabled ? 0.3 : 1))
            }
            .frame(width: 64, height: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.4))
            Text(lm.t("这个分类没有照片"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(lm.t("换一个分类试试"))
                .font(.callout)
                .foregroundStyle(.white.opacity(0.55))
            Button {
                dismiss()
            } label: {
                Text(lm.t("返回"))
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 22).padding(.vertical, 11)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - 完成态

    private var finishedState: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text(lm.t("已审核完成"))
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            if vm.pendingDeletion.isEmpty {
                Text(lm.t("没有标记任何照片待删除。"))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Text(String(format: lm.t("已标记 %d 张待删除"), vm.pendingDeletion.count))
                    .foregroundStyle(.white.opacity(0.6))
                Button {
                    showPendingSheet = true
                } label: {
                    Text(lm.t("查看待删除列表"))
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(Capsule().fill(Color.red.opacity(0.85)))
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}
