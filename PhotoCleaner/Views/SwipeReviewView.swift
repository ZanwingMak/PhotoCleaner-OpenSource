//
//  SwipeReviewView.swift
//  滑动审核：左滑前一张 / 右滑下一张 / 上滑加入待删除
//  仿参考的顶部胶囊 + 元数据条 + 底部三按钮（撤销 / 保留 / 删除）
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
                    .padding(.top, 4)

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

    // MARK: - 顶部三件套：X 关闭 / 分类胶囊 / 垃圾桶

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            // 中央胶囊：分类名 + 下拉箭头
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
                showPendingSheet = true
            } label: {
                trashWithBadge
                    .frame(width: 40, height: 40)
            }
        }
    }

    /// 垃圾桶 + 内嵌不裁切的红色 badge
    private var trashWithBadge: some View {
        ZStack(alignment: .topTrailing) {
            // 给图标留出右上角空间，badge 不会跑出 ZStack
            Image(systemName: "trash")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .padding(.top, 6)
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

    // MARK: - 元数据行（位置 / 总数 · 日期 · 时间）

    private var metaLine: some View {
        Group {
            if let asset = vm.currentAsset {
                let f = DateFormatter()
                let _ = (f.dateFormat = "yyyy年M月d日")
                let timeF = DateFormatter()
                let _ = (timeF.dateFormat = "HH:mm")
                let date = asset.creationDate ?? Date()

                HStack(spacing: 8) {
                    Text("\(vm.currentIndex + 1) / \(vm.assets.count)")
                    Text("·")
                    Text(f.string(from: date))
                    Text("·")
                    Text(timeF.string(from: date))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
            } else {
                Color.clear.frame(height: 14)
            }
        }
    }

    // MARK: - 卡片区域（包含底层卡和当前拖拽卡）

    private func cardArea(in size: CGSize) -> some View {
        ZStack {
            // 底层：下一张（如果当前是 next 方向，下一张在右；左滑时实际是 prev，那底层应该是 prev）
            if let underlying = underlyingAsset {
                PhotoCardView(asset: underlying)
                    .scaleEffect(0.95)
                    .opacity(0.6)
            }

            // 当前卡
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

    /// 底层卡选择：根据拖拽方向预览
    private var underlyingAsset: PHAsset? {
        // 拖拽过程中：若手指向左拖（dx<0）想看 prev；向右拖（dx>0）想看 next
        if dragOffset.width < -20, let prev = previewPrevAsset {
            return prev
        }
        if dragOffset.width > 20, let next = previewNextAsset {
            return next
        }
        return previewNextAsset // 默认露出下一张
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

    /// 当前卡片偏移
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

    // MARK: - 拖拽手势

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

                // 上滑优先：删除
                if v < upThreshold && abs(v) > abs(h) {
                    trigger(.markDelete, direction: .up)
                    return
                }
                // 左滑（手指向左）→ 前一张
                if h < -hThreshold {
                    if vm.canGoPrevious {
                        trigger(.previous, direction: .left)
                    } else {
                        dragOffset = .zero
                    }
                    return
                }
                // 右滑（手指向右）→ 下一张
                if h > hThreshold {
                    if vm.canGoNext {
                        trigger(.next, direction: .right)
                    } else {
                        dragOffset = .zero
                    }
                    return
                }
                // 未达阈值：回弹
                dragOffset = .zero
            }
    }

    /// 触发动作：先播离场动画，再切换数据
    private func trigger(_ action: SwipeAction, direction: ExitDirection) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle = (action == .markDelete) ? .heavy : .light
        UIImpactFeedbackGenerator(style: style).impactOccurred()

        exitDirection = direction

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            vm.handle(action)
            dragOffset = .zero
            exitDirection = .none
        }
    }

    // MARK: - 拖拽方向提示（前一张 / 下一张 / 待删除）

    private func directionOverlay(in size: CGSize) -> some View {
        ZStack {
            if dragOffset.width < -30 && dragOffset.height > -60 {
                directionLabel(text: "前一张", color: .blue, symbol: "arrow.left")
                    .opacity(min(1, abs(dragOffset.width) / 100))
                    .offset(x: -size.width * 0.25)
            }
            if dragOffset.width > 30 && dragOffset.height > -60 {
                directionLabel(text: "下一张", color: .green, symbol: "arrow.right")
                    .opacity(min(1, abs(dragOffset.width) / 100))
                    .offset(x: size.width * 0.25)
            }
            if dragOffset.height < -30 {
                directionLabel(text: "加入待删除", color: .red, symbol: "arrow.up")
                    .opacity(min(1, abs(dragOffset.height) / 130))
                    .offset(y: -size.height * 0.18)
            }
        }
        .allowsHitTesting(false)
    }

    private func directionLabel(text: String, color: Color, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .heavy))
            Text(text)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 18).padding(.vertical, 10)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color, lineWidth: 3)
        }
    }

    // MARK: - 底部三按钮（撤销 / 保留 / 删除）

    private var bottomBar: some View {
        HStack {
            // 左：撤销
            actionButton(
                symbol: "arrow.uturn.backward",
                title: "撤销",
                color: .white,
                disabled: vm.deleteHistory.isEmpty
            ) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                vm.undoLastDelete()
            }

            Spacer()

            // 中：保留（手动确认保留当前并前进）
            actionButton(
                symbol: "arrow.down",
                title: "保留",
                color: .white,
                disabled: !vm.hasMore
            ) {
                if vm.canGoNext {
                    trigger(.next, direction: .right)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            Spacer()

            // 右：删除（标记当前并前进）
            actionButton(
                symbol: "xmark",
                title: "删除",
                color: .red,
                disabled: !vm.hasMore
            ) {
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
        }
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
