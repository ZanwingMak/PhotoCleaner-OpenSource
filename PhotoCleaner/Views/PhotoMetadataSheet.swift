//
//  PhotoMetadataSheet.swift
//  照片元数据详情 sheet（SwipeReviewView 信息按钮 / PhotosBrowser 长按菜单共用）
//

import SwiftUI
import Photos
import CoreLocation

struct PhotoMetadataSheet: View {
    let asset: PHAsset
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: PhotoLibraryService
    @EnvironmentObject private var lm: LanguageManager

    @State private var image: UIImage?
    @State private var reqID: PHImageRequestID?
    @State private var resources: [PHAssetResource] = []
    @State private var totalSize: Int64 = 0
    @State private var fileName: String = "—"

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        previewImage
                        metadataCard
                        actionButtons
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle(lm.t("照片详情"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lm.t("关闭")) { dismiss() }
                        .tint(AppPalette.brand)
                }
            }
            .task {
                loadPreview()
                loadResources()
            }
        }
    }

    // MARK: - 预览图

    private var previewImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.bgCard)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
    }

    // MARK: - 元数据卡片

    private var metadataCard: some View {
        VStack(spacing: 0) {
            row(lm.t("文件名"), fileName)
            divider
            row(lm.t("尺寸"), "\(asset.pixelWidth) × \(asset.pixelHeight) px")
            divider
            row(lm.t("大小"), ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
            divider
            row(lm.t("类型"), mediaTypeText)
            divider
            row(lm.t("创建"), format(asset.creationDate))
            divider
            row(lm.t("修改"), format(asset.modificationDate))
            if let loc = asset.location {
                divider
                row(lm.t("位置"), String(format: "%.5f, %.5f",
                                   loc.coordinate.latitude,
                                   loc.coordinate.longitude))
            }
            if asset.mediaType == .video {
                divider
                row(lm.t("时长"), formatDuration(asset.duration))
            }
            if asset.isFavorite {
                divider
                row(lm.t("收藏"), lm.t("已收藏 ❤︎"))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppPalette.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.04), lineWidth: 1)
                )
        )
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppPalette.textSecondary)
                .frame(width: 56, alignment: .leading)
            Spacer(minLength: 16)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 70)
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                openInPhotosApp()
            } label: {
                actionButtonLabel(symbol: "arrow.up.right.square.fill",
                                   text: lm.t("在 照片 App 中打开"),
                                   tint: AppPalette.brand)
            }
            .buttonStyle(.plain)

            Button {
                share()
            } label: {
                actionButtonLabel(symbol: "square.and.arrow.up",
                                   text: lm.t("分享"),
                                   tint: .white)
            }
            .buttonStyle(.plain)
        }
    }

    private func actionButtonLabel(symbol: String, text: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
            Text(text)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint == .white ? AppPalette.bgCard : tint.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(tint.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - 数据加载

    private func loadPreview() {
        reqID = library.loadImage(for: asset,
                                   targetSize: CGSize(width: 800, height: 800)) { img in
            image = img
        }
    }

    private func loadResources() {
        let res = PHAssetResource.assetResources(for: asset)
        resources = res
        var total: Int64 = 0
        for r in res {
            if let size = r.value(forKey: "fileSize") as? Int64 {
                total += size
            }
        }
        totalSize = total
        fileName = res.first?.originalFilename ?? "未知"
    }

    // MARK: - 辅助

    private var mediaTypeText: String {
        if asset.mediaType == .video { return lm.t("视频") }
        if asset.mediaSubtypes.contains(.photoLive) { return lm.t("实况照片") }
        if asset.mediaSubtypes.contains(.photoScreenshot) { return lm.t("截图") }
        if asset.mediaSubtypes.contains(.photoPanorama) { return lm.t("全景照片") }
        if asset.mediaSubtypes.contains(.photoHDR) { return lm.t("HDR 照片") }
        return lm.t("照片")
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.locale = Locale(identifier: lm.effective.localeIdentifier)
        f.setLocalizedDateFormatFromTemplate("yMMMdHm")
        return f.string(from: date)
    }

    private func formatDuration(_ s: TimeInterval) -> String {
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }

    // MARK: - 操作

    /// 用 photos-redirect:// URL Scheme 打开苹果照片 App
    /// 注：iOS 不支持直接定位到特定照片，但能跳到 Photos.app 主页
    private func openInPhotosApp() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let url = URL(string: "photos-redirect://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "photos://") {
            UIApplication.shared.open(url)
        }
    }

    /// 分享：用系统 UIActivityViewController
    private func share() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let image else { return }
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        // 找到当前 active window 的 rootVC 来 present
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            // 找到最顶层的 presented controller
            var top = root
            while let presented = top.presentedViewController { top = presented }
            top.present(av, animated: true)
        }
    }
}
