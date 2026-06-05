//
//  SwipeReviewView.swift
//  滑动审核：左滑下一张 / 右滑前一张 / 上滑加入待删除（iOS 标准浏览方向）
//

import SwiftUI
import Photos

struct SwipeReviewView: View {
    let category: PhotoCategory
    @EnvironmentObject private var library: PhotoLibraryService
    @StateObject private var vm: SwipeReviewViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGSize = .zero
    @State private var exitDirection: ExitDirection = .none
    @State private var showPendingSheet = false
    @State private var toast: ToastInfo?

    enum ExitDirection { case none, left, right, up }

    init(category: PhotoCategory) {
        self.category = category
        _vm = StateObject(wrappedValue: SwipeReviewViewModel(assets: []))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                metaLine
                    .padding(.top, 6)
                    .padding(.bottom, 4)

                GeometryReader { geo in
                    ZStack {
                        if vm.assets.isEmpty {
                            ProgressView().tint(.white)
                        } else if !vm.hasMore {
                            finishedState
                        } else {
                            cardArea(in: geo.size)
                            directionOverlay(in: geo.size)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                bottomBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .toast($toast)
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPendingSheet) {
            PendingDeletionView(vm: vm)
        }
        .task {
            let assets = library.fetchAssets(for: category)
            vm.assets = assets
        }
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

            // 中央胶囊
            HStack(spacing: 6) {
                Text(category.title)
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
                let df = DateFormatter(); let _ = (df.dateFormat = "yyyy年M月d日")
                let tf = DateFormatter(); let _ = (tf.dateFormat = "HH:mm")
                let date = asset.creationDate ?? Date()

                HStack(spacing: 8) {
                    Text("\(vm.currentIndex + 1) / \(vm.assets.count)")
                    Text("·")
                    Text(df.string(from: date))
                    Text("·")
                    Text(tf.string(from: date))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
            } else {
                Color.clear.frame(height: 14)
            }
        }
    }

    // MARK: - 卡片区域

    private func cardArea(in size: CGSize) -> some View {
        ZStack {
            if let underlying = underlyingAsset {
                PhotoCardView(asset: underlying)
                    .scaleEffect(0.95)
                    .opacity(0.6)
            }

            if let asset = vm.currentAsset {
                PhotoCardView(asset: asset)
                    .id(asset.localIdentifier)
                    .offset(currentCardOffset)
                    .rotationEffect(.degrees(rotationAngle))
                    .gesture(dragGesture(in: size))
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: dragOffset)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: exitDirection)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    /// 底层卡：手指向左拖（h<0）想看下一张；向右拖（h>0）想看前一张
    private var underlyingAsset: PHAsset? {
        if dragOffset.width < -20, let next = previewNextAsset {
            return next
        }
        if dragOffset.width > 20, let prev = previewPrevAsset {
            return prev
        }
        return previewNextAsset
    }

    private var previewNextAsset: PHAsset? {
        let i = vm.currentIndex + 1
        guard i < vm.assets.count else { return nil }
        return vm.assets[i]
    }

    private var previewPrevAsset: PHAsset? {
        let i = vm.currentIndex - 1
        guard i >= 0 else { return nil }
        return vm.assets[i]
    }

    private var currentCardOffset: CGSize {
        switch exitDirection {
        case .left:  return CGSize(width: -800, height: dragOffset.height * 0.3)
        case .right: return CGSize(width: 800, height: dragOffset.height * 0.3)
        case .up:    return CGSize(width: dragOffset.width * 0.2, height: -1200)
        case .none:  return dragOffset
        }
    }

    private var rotationAngle: Double {
        guard exitDirection == .none else { return 0 }
        return Double(dragOffset.width / 28)
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    toast = ToastInfo(
                        symbol: "trash.fill",
                        text: "已加入待删除 · \(vm.pendingDeletion.count)",
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
                arrowChip(symbol: "arrow.left", label: "下一张", tint: .white)
                    .opacity(min(1, abs(dragOffset.width) / 100))
                    .scaleEffect(0.9 + min(0.2, abs(dragOffset.width) / 500))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
            }
            // 右滑 → 前一张：左侧出现小箭头玻璃片
            if dragOffset.width > 30 && dragOffset.height > -60 {
                arrowChip(symbol: "arrow.right", label: "前一张", tint: .white)
                    .opacity(min(1, abs(dragOffset.width) / 100))
                    .scaleEffect(0.9 + min(0.2, abs(dragOffset.width) / 500))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
            }
            // 上滑 → 加入待删除：屏幕顶部红色玻璃片
            if dragOffset.height < -30 {
                arrowChip(symbol: "trash.fill", label: "加入待删除", tint: .red)
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
            actionButton(symbol: "arrow.uturn.backward", title: "撤销", color: .white,
                         disabled: vm.deleteHistory.isEmpty) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                vm.undoLastDelete()
            }

            Spacer()

            actionButton(symbol: "arrow.down", title: "保留", color: .white,
                         disabled: !vm.hasMore) {
                if vm.canGoNext {
                    trigger(.next, direction: .left)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            Spacer()

            actionButton(symbol: "xmark", title: "删除", color: .red,
                         disabled: !vm.hasMore) {
                trigger(.markDelete, direction: .up)
            }
        }
        .padding(.horizontal, 20)
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

    // MARK: - 完成态

    private var finishedState: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("已审核完成")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            if vm.pendingDeletion.isEmpty {
                Text("没有标记任何照片待删除。")
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Text("已标记 \(vm.pendingDeletion.count) 张待删除")
                    .foregroundStyle(.white.opacity(0.6))
                Button {
                    showPendingSheet = true
                } label: {
                    Text("查看待删除列表")
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
