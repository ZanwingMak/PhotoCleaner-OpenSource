//
//  PhotoCardView.swift
//  单张照片卡片：检测 mediaSubtypes 自动用 LivePhotoView 或 UIImage 渲染
//  纯深色背景，不再有模糊放大底图
//

import SwiftUI
import Photos
import PhotosUI
import UIKit

struct PhotoCardView: View {
    let asset: PHAsset
    @EnvironmentObject private var library: PhotoLibraryService

    @State private var image: UIImage?
    @State private var livePhoto: PHLivePhoto?
    @State private var imageRequestID: PHImageRequestID?
    @State private var liveRequestID: PHImageRequestID?

    /// 该资产是否为 Live Photo
    private var isLivePhoto: Bool {
        asset.mediaSubtypes.contains(.photoLive)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 纯色背景（不再用模糊放大同图）
                Color(red: 0.06, green: 0.055, blue: 0.05)

                // 主图：Live Photo 用 PHLivePhotoView，否则用 UIImage
                if isLivePhoto, let livePhoto {
                    LivePhotoView(livePhoto: livePhoto)
                        .frame(width: geo.size.width, height: geo.size.height)
                } else if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .transition(.opacity)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }

                // 元信息浮层
                VStack {
                    Spacer()
                    HStack {
                        metaPill
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
            .onAppear { load(targetSize: geo.size) }
            .onDisappear { cancelLoad() }
        }
    }

    /// 元数据小药丸：尺寸 + 文件大小 + 类型角标
    private var metaPill: some View {
        let sizeStr = ByteCountFormatter.string(
            fromByteCount: PhotoClassifier.estimatedSize(of: asset),
            countStyle: .file)
        let dim = "\(asset.pixelWidth)×\(asset.pixelHeight)"

        return HStack(spacing: 6) {
            // 类型 icon
            Image(systemName: typeSymbol)
                .font(.system(size: 11, weight: .bold))
            // LIVE 角标
            if isLivePhoto {
                Text("LIVE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(Capsule().fill(.white.opacity(0.2)))
            }
            Text(dim)
                .font(.system(size: 12, weight: .medium))
            Text("·")
                .font(.system(size: 12))
                .opacity(0.6)
            Text(sizeStr)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if #available(iOS 26.0, *) {
                Capsule().fill(.clear).glassEffect(.regular, in: .capsule)
            } else {
                Capsule().fill(.ultraThinMaterial)
            }
        }
    }

    private var typeSymbol: String {
        if asset.mediaType == .video { return "video.fill" }
        if isLivePhoto { return "livephoto" }
        return "photo.fill"
    }

    /// 异步加载：Live Photo 走 requestLivePhoto；其它走普通图片
    private func load(targetSize: CGSize) {
        let scale = UIScreen.main.scale
        let target = CGSize(width: targetSize.width * scale,
                             height: targetSize.height * scale)

        if isLivePhoto {
            // 先加载静态预览图，再加载 Live Photo
            imageRequestID = library.loadImage(for: asset, targetSize: target) { img in
                withAnimation(.easeOut(duration: 0.25)) {
                    self.image = img
                }
            }
            liveRequestID = library.loadLivePhoto(for: asset, targetSize: target) { live in
                withAnimation(.easeOut(duration: 0.25)) {
                    self.livePhoto = live
                }
            }
        } else {
            imageRequestID = library.loadImage(for: asset, targetSize: target) { img in
                withAnimation(.easeOut(duration: 0.25)) {
                    self.image = img
                }
            }
        }
    }

    private func cancelLoad() {
        if let id = imageRequestID { library.cancelImageRequest(id) }
        if let id = liveRequestID { library.cancelImageRequest(id) }
    }
}
