//
//  PendingDeletionView.swift
//  待删除列表：网格预览 + 单击移除 + 批量确认删除
//

import SwiftUI
import Photos

struct PendingDeletionView: View {
    @ObservedObject var vm: SwipeReviewViewModel
    @EnvironmentObject private var library: PhotoLibraryService
    @Environment(\.dismiss) private var dismiss

    @State private var showConfirm = false
    @State private var isDeleting = false

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if vm.pendingDeletion.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(vm.pendingDeletion, id: \.localIdentifier) { asset in
                                PendingThumbnail(asset: asset) {
                                    // 点击移除
                                    if let idx = vm.pendingDeletion.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) {
                                        let g = UIImpactFeedbackGenerator(style: .soft); g.impactOccurred()
                                        _ = withAnimation { vm.pendingDeletion.remove(at: idx) }
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .padding(.bottom, 100)
                    }
                }

                // 底部固定操作栏
                if !vm.pendingDeletion.isEmpty {
                    VStack {
                        Spacer()
                        confirmBar
                    }
                }
            }
            .navigationTitle("待删除 (\(vm.pendingDeletion.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("确认删除", isPresented: $showConfirm) {
                Button("取消", role: .cancel) {}
                Button("删除 \(vm.pendingDeletion.count) 张", role: .destructive) {
                    Task { await performDelete() }
                }
            } message: {
                Text("将把 \(vm.pendingDeletion.count) 张照片移入系统「最近删除」相册，30 天内可恢复。")
            }
        }
    }

    /// 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("暂无待删除照片")
                .font(.title3.weight(.semibold))
            Text("上滑照片可加入此列表")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    /// 底部确认条
    private var confirmBar: some View {
        HStack(spacing: 12) {
            // 总大小估算
            VStack(alignment: .leading, spacing: 2) {
                Text("可释放")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(totalSizeString)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
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
                    Text(isDeleting ? "删除中…" : "确认删除")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22).padding(.vertical, 14)
                .background {
                    if #available(iOS 26.0, *) {
                        Capsule().fill(.clear).glassEffect(.regular.tint(.red.opacity(0.55)).interactive(), in: .capsule)
                    } else {
                        Capsule().fill(Color.red)
                    }
                }
            }
            .disabled(isDeleting)
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

    /// 计算所有待删除资产的总大小
    private var totalSizeString: String {
        let total = vm.pendingDeletion.reduce(Int64(0)) { sum, asset in
            sum + PhotoClassifier.estimatedSize(of: asset)
        }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    /// 执行删除（系统会弹原生确认框）
    private func performDelete() async {
        isDeleting = true
        let assets = vm.pendingDeletion
        let success = await library.deleteAssets(assets)
        isDeleting = false
        if success {
            vm.clearAfterDelete()
            // 删除后刷新分类计数
            await library.refreshCategoryCounts()
            dismiss()
        }
    }
}

/// 单张待删除缩略图
struct PendingThumbnail: View {
    let asset: PHAsset
    let onRemove: () -> Void
    @EnvironmentObject private var library: PhotoLibraryService

    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        // 用 padding 让 ZStack 整体有空间容纳 × 按钮在角落，按钮不被 grid cell 边界裁切
        ZStack {
            // 缩略图
            ZStack {
                Color(.systemGray6)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(6) // 给 × 留位置

            // 移除按钮：右上角，落在 padding 区域内
            VStack {
                HStack {
                    Spacer()
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, .black.opacity(0.65))
                            .background(Circle().fill(.white).padding(4))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .onAppear {
            requestID = library.loadImage(for: asset, targetSize: CGSize(width: 280, height: 280)) { img in
                image = img
            }
        }
        .onDisappear {
            if let id = requestID { library.cancelImageRequest(id) }
        }
    }
}
