//
//  PhotoCardView.swift
//  单张照片卡片：使用静态预览图渲染，避免审核页批量加载 Live Photo 资源
//  纯深色背景，不再有模糊放大底图
//

import SwiftUI
import Photos
import UIKit

/// 全局缩略图缓存：view 重建时立即取，不闪 Loading
enum ThumbnailCache {
    static let shared: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 80
        c.totalCostLimit = 80 * 1024 * 1024
        return c
    }()

    /// 从缓存读取指定 localIdentifier 的预览图
    static func get(_ id: String) -> UIImage? {
        shared.object(forKey: id as NSString)
    }

    /// 写入预览图并按像素估算内存成本，防止连续浏览时缓存过大
    static func set(_ id: String, _ image: UIImage) {
        let pixels = image.size.width * image.scale * image.size.height * image.scale
        let cost = max(1, Int(pixels * 4))
        shared.setObject(image, forKey: id as NSString, cost: cost)
    }
}

struct PhotoCardView: View {
    let asset: PHAsset
    @EnvironmentObject private var library: PhotoLibraryService

    @State private var image: UIImage?
    @State private var imageRequestID: PHImageRequestID?

    /// init 时立即从缓存取 image，避免重建 view 时闪 Loading
    init(asset: PHAsset) {
        self.asset = asset
        _image = State(initialValue: ThumbnailCache.get(asset.localIdentifier))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 仅在加载中显示深色底，加载完后透明（让堆叠下层照片可见）
                if image == nil {
                    Color(red: 0.06, green: 0.055, blue: 0.05)
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }

                if let image {
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

    /// 异步加载静态预览：先用缓存，缺时才请求
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
    }

    /// 取消当前卡片未完成的图片请求
    private func cancelLoad() {
        if let id = imageRequestID { library.cancelImageRequest(id) }
    }
}
