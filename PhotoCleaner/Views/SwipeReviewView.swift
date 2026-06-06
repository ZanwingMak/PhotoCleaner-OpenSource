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
            .preferredColorScheme(.dark)
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
    @State private var exitDirection: ExitDirection = .none
    @State private var showPendingSheet = false
    @State private var toast: ToastInfo?
    @State private var hasLoaded = false
    @State private var showCategoryPicker = false
    @State private var showMetadata = false
    @State private var currentCategory: PhotoCategory

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
                switchCategory(to: newCategory)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
                dismiss()
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

            if let prev = prevAsset, !isVerticalDrag {
                PhotoCardView(asset: prev)
                    .scaleEffect(prevScale)
                    .offset(x: prevOffsetX(in: size))
                    .rotation3DEffect(
                        .degrees(prevRotationY),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.8
                    )
                    .opacity(prevOpacity)
                    .allowsHitTesting(false)
                    .zIndex(1)
            }

            if let next = nextAsset, !isVerticalDrag {
                PhotoCardView(asset: next)
                    .scaleEffect(nextScale)
                    .offset(x: nextOffsetX(in: size))
                    .rotation3DEffect(
                        .degrees(nextRotationY),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.8
                    )
                    .opacity(nextOpacity)
                    .allowsHitTesting(false)
                    .zIndex(1)
            }

            // 当前卡：横向拖时缩放 + 3D 倾斜；上滑/离场用 currentCardOffset
            if let asset = vm.currentAsset {
                PhotoCardView(asset: asset)
                    .id(asset.localIdentifier)
                    .scaleEffect(currentScale)
                    .offset(currentCardOffset)
                    .rotation3DEffect(
                        .degrees(currentRotationY),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.8
                    )
                    .gesture(dragGesture(in: size))
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: dragOffset)
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: exitDirection)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(10)
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
        guard exitDirection == .none else { return 1 }
        return 1 - abs(swipeProgress) * 0.12
    }

    /// 当前卡 Y 轴旋转：朝手指反方向翻开（左滑→右倾 +35°，让 next 露出）
    private var currentRotationY: Double {
        guard exitDirection == .none else { return 0 }
        return Double(-swipeProgress * 35)
    }

    // 显现速度系数：拖动 1/5 进度（约 72pt）就完全不透明
    private static let opacityBoost: Double = 5

    /// 前一张 X 偏移：静止 -0.55w（左外），右滑到 +1 时移到 0（中心）
    private func prevOffsetX(in size: CGSize) -> CGFloat {
        let restX = -size.width * 0.55
        // progress 0 → restX；progress +1 → 0；公式 restX * (1 - max(0, progress))
        return restX * (1 - max(0, swipeProgress))
    }

    private var prevScale: CGFloat {
        0.82 + max(0, swipeProgress) * 0.18
    }

    /// 前一张静止 +45° 倾斜 → progress +1 时翻正
    private var prevRotationY: Double {
        Double(45 - max(0, swipeProgress) * 45)
    }

    /// 前一张不透明度：右滑（progress > 0）时快速显现
    private var prevOpacity: Double {
        min(1.0, max(0, Double(swipeProgress)) * Self.opacityBoost)
    }

    /// 下一张 X 偏移：静止 +0.55w（右外），左滑到 -1 时到 0（中心）
    private func nextOffsetX(in size: CGSize) -> CGFloat {
        let restX = size.width * 0.55
        // progress 0 → restX；progress -1 → 0；公式 restX * (1 - max(0, -progress))
        return restX * (1 - max(0, -swipeProgress))
    }

    private var nextScale: CGFloat {
        0.82 + max(0, -swipeProgress) * 0.18
    }

    /// 下一张静止 -45° 倾斜（从右侧侧倾）→ progress -1 时翻正
    private var nextRotationY: Double {
        Double(-45 + max(0, -swipeProgress) * 45)
    }

    /// 下一张不透明度：左滑（progress < 0）时快速显现
    private var nextOpacity: Double {
        min(1.0, max(0, Double(-swipeProgress)) * Self.opacityBoost)
    }

    private var currentCardOffset: CGSize {
        switch exitDirection {
        case .left:  return CGSize(width: -800, height: dragOffset.height * 0.3)
        case .right: return CGSize(width: 800, height: dragOffset.height * 0.3)
        case .up:    return CGSize(width: dragOffset.width * 0.2, height: -1200)
        case .none:  return dragOffset
        }
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

    /// 触发动作 + toast
    private func trigger(_ action: SwipeAction, direction: ExitDirection) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle = (action == .markDelete) ? .heavy : .light
        UIImpactFeedbackGenerator(style: style).impactOccurred()

        exitDirection = direction

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            vm.handle(action)
            dragOffset = .zero
            exitDirection = .none

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
