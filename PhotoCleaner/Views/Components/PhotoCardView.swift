//
//  PhotoCardView.swift
//  单张照片卡片：检测 mediaSubtypes 自动用 LivePhotoView 或 UIImage 渲染
//  纯深色背景，不再有模糊放大底图
//

import SwiftUI
import Photos
import PhotosUI
import UIKit

/// 全局缩略图缓存：view 重建时立即取，不闪 Loading
enum ThumbnailCache {
    static let shared: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 300
        return c
    }()

    static func get(_ id: String) -> UIImage? {
        shared.object(forKey: id as NSString)
    }

    static func set(_ id: String, _ image: UIImage) {
        shared.setObject(image, forKey: id as NSString)
    }
}

struct PhotoCardView: View {
    let asset: PHAsset
    @EnvironmentObject private var library: PhotoLibraryService

    @State private var image: UIImage?
    @State private var livePhoto: PHLivePhoto?
    @State private var imageRequestID: PHImageRequestID?
    @State private var liveRequestID: PHImageRequestID?

    /// init 时立即从缓存取 image，避免重建 view 时闪 Loading
    init(asset: PHAsset) {
        self.asset = asset
        _image = State(initialValue: ThumbnailCache.get(asset.localIdentifier))
    }

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
            // 已去掉边框 strokeBorder 和外阴影 shadow（防止深色背景的"画框感"）
            .onAppear { load(targetSize: geo.size) }
            .onDisappear { cancelLoad() }
        }
    }

    /// 异步加载：先用缓存，缺时才请求；Live Photo 额外加载
    private func load(targetSize: CGSize) {
        let scale = UIScreen.main.scale
        let target = CGSize(width: targetSize.width * scale,
                             height: targetSize.height * scale)

        // 静态图：已有 cache 就不重新加载，避免切换时闪
        if image == nil {
            imageRequestID = library.loadImage(for: asset, targetSize: target) { img in
                guard let img else { return }
                ThumbnailCache.set(asset.localIdentifier, img)
                self.image = img // 静默赋值，无 withAnimation 避免闪烁
            }
        }

        if isLivePhoto, livePhoto == nil {
            liveRequestID = library.loadLivePhoto(for: asset, targetSize: target) { live in
                self.livePhoto = live
            }
        }
    }

    private func cancelLoad() {
        if let id = imageRequestID { library.cancelImageRequest(id) }
        if let id = liveRequestID { library.cancelImageRequest(id) }
    }
}
