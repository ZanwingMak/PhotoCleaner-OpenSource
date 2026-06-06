//
//  PhotoDetailView.swift
//  全屏大图浏览：左右翻页 + 双击/捏合缩放 + 顶部信息按钮 + 跳 Photos.app
//

import SwiftUI
import Photos

struct PhotoDetailView: View {
    let assets: [PHAsset]
    let startAsset: PHAsset

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: PhotoLibraryService

    @State private var currentIndex: Int = 0
    @State private var showMetadata = false
    @State private var showChrome = true   // 顶部/底部 UI 是否显示
    @State private var isFavorite = false  // 当前照片是否收藏（独立 state，避免 PHAsset 不刷新）
    @State private var assetsRefreshTick = 0 // 用于强制刷新 PHAsset 状态

    private var currentAsset: PHAsset? {
        guard currentIndex >= 0, currentIndex < assets.count else { return nil }
        // 重新 fetch 拿最新 PHAsset（修改 isFavorite 等需要新实例）
        _ = assetsRefreshTick
        let id = assets[currentIndex].localIdentifier
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        return fetched.firstObject ?? assets[currentIndex]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 翻页：用 TabView 的 page 样式
            TabView(selection: $currentIndex) {
                ForEach(assets.indices, id: \.self) { idx in
                    ZoomablePhoto(asset: assets[idx])
                        .tag(idx)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showChrome.toggle()
                            }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // 顶部工具栏
            if showChrome {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    Spacer()
                    bottomBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .transition(.opacity)
            }
        }
        .statusBarHidden(!showChrome)
        .onAppear {
            currentIndex = assets.firstIndex(where: { $0.localIdentifier == startAsset.localIdentifier }) ?? 0
            refreshFavoriteState()
        }
        .onChange(of: currentIndex) { _, _ in
            refreshFavoriteState()
        }
        .sheet(isPresented: $showMetadata) {
            if let asset = currentAsset {
                PhotoMetadataSheet(asset: asset)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 顶部栏

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.black.opacity(0.5)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            if let asset = currentAsset {
                VStack(spacing: 2) {
                    Text("\(currentIndex + 1) / \(assets.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(formattedDate(asset.creationDate))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(.black.opacity(0.45)))
            }

            Spacer()

            Button {
                showMetadata = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.black.opacity(0.5)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 底部栏

    private var bottomBar: some View {
        HStack(spacing: 18) {
            // 收藏 / 取消收藏（用 isFavorite state 而非 PHAsset.isFavorite，保证即时刷新）
            iconButton(symbol: isFavorite ? "heart.fill" : "heart",
                        tint: isFavorite ? .red : .white) {
                toggleFavorite()
            }

            Spacer()

            // 分享
            iconButton(symbol: "square.and.arrow.up", tint: .white) {
                share()
            }

            // 在 Photos.app 中打开
            iconButton(symbol: "arrow.up.right.square", tint: .white) {
                openInPhotosApp()
            }

            // 详情
            iconButton(symbol: "info.circle.fill", tint: AppPalette.brand) {
                showMetadata = true
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(.black.opacity(0.6))
                .overlay(Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 1))
        )
    }

    private func iconButton(symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 操作

    private func toggleFavorite() {
        guard let asset = currentAsset else { return }
        let newValue = !asset.isFavorite
        // 立即更新 UI state，避免等系统回调的延迟
        isFavorite = newValue

        PHPhotoLibrary.shared().performChanges({
            let r = PHAssetChangeRequest(for: asset)
            r.isFavorite = newValue
        }, completionHandler: { success, _ in
            DispatchQueue.main.async {
                if success {
                    // 强制 fetch 最新 PHAsset
                    assetsRefreshTick += 1
                } else {
                    // 失败回滚
                    isFavorite = !newValue
                }
            }
        })
    }

    /// 切换当前照片时同步 isFavorite state
    private func refreshFavoriteState() {
        isFavorite = currentAsset?.isFavorite ?? false
    }

    private func openInPhotosApp() {
        if let url = URL(string: "photos-redirect://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "photos://") {
            UIApplication.shared.open(url)
        }
    }

    private func share() {
        guard let asset = currentAsset else { return }
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        PHCachingImageManager().requestImage(for: asset,
                                              targetSize: PHImageManagerMaximumSize,
                                              contentMode: .aspectFit,
                                              options: options) { image, _ in
            guard let image else { return }
            DispatchQueue.main.async {
                let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                   let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                    var top = root
                    while let presented = top.presentedViewController { top = presented }
                    top.present(av, animated: true)
                }
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日 HH:mm"
        return f.string(from: date)
    }
}

// MARK: - 单张可缩放照片

private struct ZoomablePhoto: View {
    let asset: PHAsset
    @EnvironmentObject private var library: PhotoLibraryService

    @State private var image: UIImage?
    @State private var livePhoto: PHLivePhoto?
    @State private var reqID: PHImageRequestID?
    @State private var liveReqID: PHImageRequestID?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private var isLivePhoto: Bool {
        asset.mediaSubtypes.contains(.photoLive)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                // Live Photo 用 PHLivePhotoView（自动触摸长按播放），无 zoom
                if isLivePhoto, let livePhoto {
                    LivePhotoView(livePhoto: livePhoto)
                        .frame(width: geo.size.width, height: geo.size.height)
                } else if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            // 捏合缩放
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1, min(4, lastScale * value))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1.05 {
                                        withAnimation(.spring()) {
                                            scale = 1; lastScale = 1
                                            offset = .zero; lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            // 平移
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            // 双击切换 1x / 2x
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                if scale > 1 {
                                    scale = 1; lastScale = 1
                                    offset = .zero; lastOffset = .zero
                                } else {
                                    scale = 2; lastScale = 2
                                }
                            }
                        }
                } else {
                    ProgressView().tint(.white)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            let s = UIScreen.main.scale
            let size = CGSize(width: 1200 * s, height: 1200 * s)
            reqID = library.loadImage(for: asset, targetSize: size) { img in
                image = img
            }
            // 如果是 Live Photo，额外取 PHLivePhoto
            if isLivePhoto {
                liveReqID = library.loadLivePhoto(for: asset, targetSize: size) { live in
                    livePhoto = live
                }
            }
        }
        .onDisappear {
            if let id = reqID { library.cancelImageRequest(id) }
            if let id = liveReqID { library.cancelImageRequest(id) }
        }
    }
}
