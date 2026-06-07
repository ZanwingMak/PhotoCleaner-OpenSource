//
//  PendingDeletionView.swift
//  待删除列表：多选网格 + 全选切换 + 批量删除选中项
//

import SwiftUI
import Photos

struct PendingDeletionView: View {
    @ObservedObject var vm: SwipeReviewViewModel
    @EnvironmentObject private var library: PhotoLibraryService
    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    /// 选中的 localIdentifier 集合（默认进入时全选）
    @State private var selectedIds = Set<String>()
    @State private var hasInitialized = false
    @State private var showConfirm = false
    @State private var isDeleting = false

    // 固定 3 列，每个 cell 1:1 正方形，避免自适应导致缩略图大小不一/横向拉伸重叠
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    /// 当前选中的资产
    private var selectedAssets: [PHAsset] {
        vm.pendingDeletion.filter { selectedIds.contains($0.localIdentifier) }
    }

    /// 是否全选
    private var isAllSelected: Bool {
        !vm.pendingDeletion.isEmpty &&
            selectedIds.count == vm.pendingDeletion.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary.ignoresSafeArea()

                if vm.pendingDeletion.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(vm.pendingDeletion, id: \.localIdentifier) { asset in
                                PendingThumbnail(
                                    asset: asset,
                                    isSelected: selectedIds.contains(asset.localIdentifier),
                                    onTap: { toggle(asset) }
                                )
                            }
                        }
                        .padding(12)
                        .padding(.bottom, 100)
                    }
                }

                if !vm.pendingDeletion.isEmpty {
                    VStack {
                        Spacer()
                        confirmBar
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("\(lm.t("待删除")) (\(vm.pendingDeletion.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(lm.t("关闭")) { dismiss() }
                        .tint(AppPalette.brand)
                }
                if !vm.pendingDeletion.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            toggleAll()
                        } label: {
                            Text(isAllSelected ? lm.t("全不选") : lm.t("全选"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppPalette.brand)
                        }
                    }
                }
            }
            .alert(lm.t("确认删除"), isPresented: $showConfirm) {
                Button(lm.t("取消"), role: .cancel) {}
                Button(String(format: lm.t("删除 %d 张"), selectedAssets.count),
                       role: .destructive) {
                    Task { await performDelete() }
                }
            } message: {
                Text(String(format: lm.t("将把 %d 张照片移入系统「最近删除」相册，30 天内可恢复。"),
                            selectedAssets.count))
            }
            .onAppear {
                if !hasInitialized {
                    // 默认全选
                    selectedIds = Set(vm.pendingDeletion.map { $0.localIdentifier })
                    hasInitialized = true
                }
            }
        }
    }

    // MARK: - 多选交互

    /// 单击切换选中
    private func toggle(_ asset: PHAsset) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        let id = asset.localIdentifier
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            if selectedIds.contains(id) {
                selectedIds.remove(id)
            } else {
                selectedIds.insert(id)
            }
        }
    }

    /// 全选 / 全不选
    private func toggleAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if isAllSelected {
                selectedIds.removeAll()
            } else {
                selectedIds = Set(vm.pendingDeletion.map { $0.localIdentifier })
            }
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(AppPalette.textTertiary)
            Text(lm.t("暂无待删除照片"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
            Text(lm.t("上滑照片可加入此列表"))
                .font(.callout)
                .foregroundStyle(AppPalette.textSecondary)
        }
    }

    // MARK: - 底部条

    private var confirmBar: some View {
        HStack(spacing: 12) {
            // 已选数 + 可释放
            VStack(alignment: .leading, spacing: 2) {
                Text("\(lm.t("可释放")) · \(selectedAssets.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(AppPalette.textSecondary)
                Text(totalSizeString)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)
            }

            Spacer()

            Button {
                showConfirm = true
            } label: {
                HStack(spacing: 8) {
                    if isDeleting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text(isDeleting ? lm.t("删除中…") : lm.t("确认删除"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22).padding(.vertical, 14)
                .background {
                    if #available(iOS 26.0, *) {
                        Capsule().fill(.clear)
                            .glassEffect(.regular.tint(.red.opacity(0.55)).interactive(), in: .capsule)
                    } else {
                        Capsule().fill(Color.red)
                    }
                }
            }
            .disabled(isDeleting || selectedAssets.isEmpty)
            .opacity(selectedAssets.isEmpty ? 0.4 : 1)
        }
        .padding(16)
        .background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 28).fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 28))
            } else {
                RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    /// 当前选中资产的累计大小
    private var totalSizeString: String {
        let total = selectedAssets.reduce(Int64(0)) { sum, asset in
            sum + PhotoClassifier.estimatedSize(of: asset)
        }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    /// 只删除选中项；未选中的留在 pendingDeletion
    private func performDelete() async {
        let toDelete = selectedAssets
        guard !toDelete.isEmpty else { return }
        isDeleting = true
        let success = await library.deleteAssets(toDelete)
        isDeleting = false
        if success {
            let deletedIds = Set(toDelete.map { $0.localIdentifier })
            vm.pendingDeletion.removeAll { deletedIds.contains($0.localIdentifier) }
            vm.assets.removeAll { deletedIds.contains($0.localIdentifier) }
            vm.deleteHistory.removeAll { deletedIds.contains($0.asset.localIdentifier) }
            vm.currentIndex = min(vm.currentIndex, max(0, vm.assets.count - 1))
            selectedIds.removeAll()
            await library.refreshCategoryCounts()
            dismiss()
        }
    }
}

// MARK: - 多选缩略图

struct PendingThumbnail: View {
    let asset: PHAsset
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject private var library: PhotoLibraryService

    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        // 用 Color.clear + aspectRatio 1:1 占据正方形空间，
        // 然后 GeometryReader 内强制 image / overlay 用 cell 实际宽度，避免溢出重叠
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    Button {
                        onTap()
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            // 缩略图层
                            ZStack {
                                Color(red: 0.13, green: 0.12, blue: 0.11)
                                if let image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: side, height: side)
                                }
                            }
                            .frame(width: side, height: side)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(AppPalette.brand.opacity(0.18))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(AppPalette.brand, lineWidth: 3)
                                        )
                                }
                            }

                            // 右上角勾选
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(
                                    isSelected ? AppPalette.brand : Color.white.opacity(0.9),
                                    isSelected ? Color.white : Color.black.opacity(0.45)
                                )
                                .padding(6)
                        }
                        .frame(width: side, height: side)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                requestID = library.loadImage(for: asset,
                                               targetSize: CGSize(width: 280, height: 280)) { img in
                    image = img
                }
            }
            .onDisappear {
                if let id = requestID { library.cancelImageRequest(id) }
            }
    }
}
