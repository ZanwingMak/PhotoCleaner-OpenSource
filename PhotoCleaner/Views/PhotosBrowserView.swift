//
//  PhotosBrowserView.swift
//  「照片」Tab：全库照片 3 列缩略图网格，点击进入滑动审核
//

import SwiftUI
import Photos

struct PhotosBrowserView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @Environment(\.dismiss) private var dismiss

    @State private var assets: [PHAsset] = []
    @State private var hasLoaded = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary.ignoresSafeArea()

                if !hasLoaded {
                    ProgressView().tint(AppPalette.brand)
                } else if assets.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(assets, id: \.localIdentifier) { asset in
                                PhotoGridThumb(asset: asset)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("全部照片 · \(assets.count)")
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
                assets = fetched
                hasLoaded = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(AppPalette.textTertiary)
            Text("照片库为空")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppPalette.textPrimary)
            Text("先在系统相机或文件 App 里添加照片")
                .font(.system(size: 13))
                .foregroundStyle(AppPalette.textSecondary)
        }
    }
}

/// 单个网格缩略图
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
                // 视频角标
                if asset.mediaType == .video {
                    Image(systemName: "video.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Capsule().fill(.black.opacity(0.55)))
                        .padding(4)
                }
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
