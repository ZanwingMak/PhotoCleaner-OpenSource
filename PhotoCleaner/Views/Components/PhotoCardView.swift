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
                // 仅在加载中显示深色底，加载完后透明（让堆叠下层照片可见）
                if image == nil && livePhoto == nil {
                    Color(red: 0.06, green: 0.055, blue: 0.05)
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }

                if isLivePhoto, let livePhoto {
                    LivePhotoView(livePhoto: livePhoto)
                        .frame(width: geo.size.width, height: geo.size.height)
                } else if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .transition(.opacity)
                }

                // 元信息浮层由外层 SwipeReviewView 渲染，不再画在卡内
                // 避免卡片飞出时元数据胶囊跟随抖动
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
