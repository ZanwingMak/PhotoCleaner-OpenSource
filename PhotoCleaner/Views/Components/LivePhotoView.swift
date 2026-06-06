//
//  LivePhotoView.swift
//  PHLivePhotoView 的 SwiftUI 包装
//

import SwiftUI
import Photos
import PhotosUI

/// 显示 PHLivePhoto 的 SwiftUI 视图
struct LivePhotoView: UIViewRepresentable {
    let livePhoto: PHLivePhoto?
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var autoPlay: Bool = true   // 加载完成后自动播放一次

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = contentMode
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
        if autoPlay, livePhoto != nil {
            // 短暂延迟后播放一次 hint
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                uiView.startPlayback(with: .hint)
            }
        }
    }
}
