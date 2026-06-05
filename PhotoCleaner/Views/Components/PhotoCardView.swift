//
//  PhotoCardView.swift
//  单张照片卡片：从 PHAsset 加载图像，附液态玻璃边框
//

import SwiftUI
import Photos
import UIKit

/// 单张照片卡片视图
struct PhotoCardView: View {
    let asset: PHAsset
    @EnvironmentObject private var library: PhotoLibraryService

    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景：模糊放大的同图，营造电影感外框
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: 40)
                        .opacity(0.55)
                        .clipped()
                } else {
                    Color(.systemGray6)
                }

                // 主图
                if let image {
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

                // 元信息浮层（左下角）
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
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
            .onAppear { loadImage(targetSize: geo.size) }
            .onDisappear { cancelLoad() }
        }
    }

    /// 元数据小药丸：尺寸 + 文件大小
    private var metaPill: some View {
        let sizeStr = ByteCountFormatter.string(
            fromByteCount: PhotoClassifier.estimatedSize(of: asset),
            countStyle: .file)
        let dim = "\(asset.pixelWidth)×\(asset.pixelHeight)"

        return HStack(spacing: 6) {
            Image(systemName: asset.mediaType == .video ? "video.fill" : "photo.fill")
                .font(.system(size: 11, weight: .semibold))
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

    /// 异步加载图像，使用屏幕 2x 分辨率
    private func loadImage(targetSize: CGSize) {
        let scale = UIScreen.main.scale
        let target = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)
        requestID = library.loadImage(for: asset, targetSize: target) { img in
            withAnimation(.easeOut(duration: 0.25)) {
                self.image = img
            }
        }
    }

    /// 离开屏幕时取消请求，避免内存浪费
    private func cancelLoad() {
        if let id = requestID {
            library.cancelImageRequest(id)
        }
    }
}
