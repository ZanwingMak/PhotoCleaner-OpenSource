//
//  PhotosBrowserView.swift
//  「照片」Tab：3 列缩略图 + 顶部筛选 + 长按 ContextMenu + 点击进入大图预览
//

import SwiftUI
import Photos

/// 筛选维度
enum PhotosFilter: String, CaseIterable, Identifiable {
    case all       // 全部
    case favorite  // 收藏
    case video     // 视频
    case screenshot // 截图

    var id: String { rawValue }
    var title: String {
        switch self {
        case .all:        return "全部"
        case .favorite:   return "收藏"
        case .video:      return "视频"
        case .screenshot: return "截图"
        }
    }
    var symbol: String {
        switch self {
        case .all:        return "square.grid.3x3.fill"
        case .favorite:   return "heart.fill"
        case .video:      return "video.fill"
        case .screenshot: return "rectangle.dashed"
        }
    }
}

struct PhotosBrowserView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var allAssets: [PHAsset] = []
    @State private var hasLoaded = false
    @State private var filter: PhotosFilter = .all
    @State private var previewAsset: PHAsset?
    @State private var metadataAsset: PHAsset?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    /// 当前筛选后的资产
    private var filteredAssets: [PHAsset] {
        switch filter {
        case .all:        return allAssets
        case .favorite:   return allAssets.filter { $0.isFavorite }
        case .video:      return allAssets.filter { $0.mediaType == .video }
        case .screenshot: return allAssets.filter { $0.mediaSubtypes.contains(.photoScreenshot) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 8)

                    if !hasLoaded {
                        Spacer()
                        ProgressView().tint(AppPalette.brand)
                        Spacer()
                    } else if filteredAssets.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(filteredAssets, id: \.localIdentifier) { asset in
                                    PhotoGridThumb(asset: asset)
                                        .onTapGesture {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            previewAsset = asset
                                        }
                                        .contextMenu {
                                            assetMenu(for: asset)
                                        }
                                }
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("\(lm.t("照片")) · \(filteredAssets.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppPalette.textPrimary)
                    }
                }
            }
            .task {
                let fetched = library.fetchAssets(for: .allPhotos)
                allAssets = fetched
                hasLoaded = true
            }
            .fullScreenCover(item: Binding(
                get: { previewAsset.map { PHAssetWrapper(asset: $0) } },
                set: { previewAsset = $0?.asset }
            )) { wrapper in
                PhotoDetailView(assets: filteredAssets, startAsset: wrapper.asset)
            }
            .sheet(item: Binding(
                get: { metadataAsset.map { PHAssetWrapper(asset: $0) } },
                set: { metadataAsset = $0?.asset }
            )) { wrapper in
                PhotoMetadataSheet(asset: wrapper.asset)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 顶部筛选条

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PhotosFilter.allCases) { f in
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            filter = f
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: f.symbol)
                                .font(.system(size: 12, weight: .bold))
                            Text(lm.t(f.title))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(filter == f ? .white : AppPalette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background {
                            if filter == f {
                                Capsule().fill(AppPalette.brandGradient)
                            } else {
                                Capsule().fill(Color.white.opacity(0.08))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// 长按 contextMenu
    @ViewBuilder
    private func assetMenu(for asset: PHAsset) -> some View {
        Button {
            previewAsset = asset
        } label: {
            Label(lm.t("查看大图"), systemImage: "rectangle.expand.vertical")
        }
        Button {
            metadataAsset = asset
        } label: {
            Label(lm.t("照片信息"), systemImage: "info.circle")
        }
        Button {
            openInPhotosApp()
        } label: {
            Label(lm.t("在 照片 App 中打开"), systemImage: "arrow.up.right.square")
        }
    }

    private func openInPhotosApp() {
        if let url = URL(string: "photos-redirect://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "photos://") {
            UIApplication.shared.open(url)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(AppPalette.textTertiary)
            Text(lm.t("没有符合的照片"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppPalette.textPrimary)
            Text(lm.t("换个筛选条件试试"))
                .font(.system(size: 13))
                .foregroundStyle(AppPalette.textSecondary)
        }
    }
}

/// PHAsset 包装，让其符合 Identifiable 用于 sheet/cover binding
struct PHAssetWrapper: Identifiable {
    let asset: PHAsset
    var id: String { asset.localIdentifier }
}

// MARK: - 网格缩略图

private struct PhotoGridThumb: View {
    let asset: PHAsset
    @EnvironmentObject private var library: PhotoLibraryService
    @State private var image: UIImage?
    @State private var reqID: PHImageRequestID?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                Color(red: 0.13, green: 0.12, blue: 0.11)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                }

                // 角标组合
                HStack(spacing: 4) {
                    if asset.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    if asset.mediaType == .video {
                        Image(systemName: "video.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    if asset.mediaSubtypes.contains(.photoScreenshot) {
                        Image(systemName: "rectangle.dashed")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(4)
                .background(
                    Capsule().fill(.black.opacity(0.45))
                        .opacity(asset.isFavorite || asset.mediaType == .video
                                  || asset.mediaSubtypes.contains(.photoScreenshot) ? 1 : 0)
                )
                .padding(4)
            }
            .frame(width: geo.size.width, height: geo.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            reqID = library.loadImage(for: asset, targetSize: CGSize(width: 240, height: 240)) { img in
                image = img
            }
        }
        .onDisappear {
            if let id = reqID { library.cancelImageRequest(id) }
        }
    }
}
