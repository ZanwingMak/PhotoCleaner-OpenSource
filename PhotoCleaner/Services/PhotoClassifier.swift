//
//  PhotoClassifier.swift
//  基于资产元数据的来源推断 + 快速合集筛选
//

import Foundation
import Photos
import UIKit

enum PhotoClassifier {

    /// 推断分类匹配
    static func matches(_ asset: PHAsset, kind: PhotoCategory.InferredKind) -> Bool {
        switch kind {
        case .allUnsorted:
            return true
        case .unsortedVideo:
            return asset.mediaType == .video
        case .screenshot:
            return asset.mediaSubtypes.contains(.photoScreenshot)
        case .oldScreenshot:
            return isOldScreenshot(asset)
        case .selfie:
            return isLikelySelfie(asset)
        case .camera:
            let pixels = asset.pixelWidth * asset.pixelHeight
            return pixels >= 8_000_000 && !asset.mediaSubtypes.contains(.photoScreenshot)
        case .social:
            let pixels = asset.pixelWidth * asset.pixelHeight
            return pixels < 2_000_000 && pixels > 0
                && asset.mediaType == .image
                && !asset.mediaSubtypes.contains(.photoScreenshot)
        case .lowResolution:
            return isLowResolutionImage(asset)
        case .landscape:
            return asset.pixelWidth > asset.pixelHeight && asset.mediaType == .image
        case .portrait:
            return asset.pixelHeight > asset.pixelWidth && asset.mediaType == .image
        case .largeFile:
            return estimatedSize(of: asset) > 5 * 1024 * 1024
        }
    }

    /// 快速合集筛选
    static func matches(_ asset: PHAsset, quick: PhotoCategory.QuickPick, now: Date = Date()) -> Bool {
        guard let date = asset.creationDate else { return false }
        let cal = Calendar.current
        switch quick {
        case .random:
            return true // 随机分类后端用 shuffle 选样
        case .thisWeek:
            return cal.isDate(date, equalTo: now, toGranularity: .weekOfYear)
                && cal.isDate(date, equalTo: now, toGranularity: .year)
        case .onThisDay:
            let m1 = cal.component(.month, from: date), d1 = cal.component(.day, from: date)
            let m2 = cal.component(.month, from: now),  d2 = cal.component(.day, from: now)
            return m1 == m2 && d1 == d2
        case .lastYear:
            let y1 = cal.component(.year, from: date)
            let y2 = cal.component(.year, from: now)
            return y1 == y2 - 1
        }
    }

    /// 首页全库扫描使用的轻量匹配，避免启动时逐张读取资源文件大小
    static func matchesForLibraryScan(_ asset: PHAsset, kind: PhotoCategory.InferredKind) -> Bool {
        if kind == .largeFile {
            return isLikelyLargeFileByMetadata(asset)
        }
        return matches(asset, kind: kind)
    }

    /// 估算资产文件大小（字节）
    static func estimatedSize(of asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        var total: Int64 = 0
        for r in resources {
            if let size = r.value(forKey: "fileSize") as? Int64 {
                total += size
            }
        }
        return total
    }

    /// 只用元数据粗略判断大文件，避免全库统计时触发昂贵资源查询
    private static func isLikelyLargeFileByMetadata(_ asset: PHAsset) -> Bool {
        let pixels = Int64(asset.pixelWidth) * Int64(asset.pixelHeight)
        if asset.mediaType == .video {
            return asset.duration >= 30 || pixels >= 8_000_000
        }
        return asset.mediaSubtypes.contains(.photoPanorama) || pixels >= 12_000_000
    }

    /// 判断是否是 90 天以前的截图，用于让「陈年截图」入口和文案一致
    private static func isOldScreenshot(_ asset: PHAsset) -> Bool {
        guard asset.mediaSubtypes.contains(.photoScreenshot),
              let date = asset.creationDate,
              let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())
        else { return false }
        return date < cutoff
    }

    /// 判断是否是低分辨率图片，用于替代模糊的社交媒体来源推断
    private static func isLowResolutionImage(_ asset: PHAsset) -> Bool {
        let pixels = asset.pixelWidth * asset.pixelHeight
        return pixels > 0
            && pixels < 2_000_000
            && asset.mediaType == .image
            && !asset.mediaSubtypes.contains(.photoScreenshot)
    }

    /// 根据常见前摄尺寸粗略判断自拍
    private static func isLikelySelfie(_ asset: PHAsset) -> Bool {
        let w = asset.pixelWidth, h = asset.pixelHeight
        let frontCamSizes: [(Int, Int)] = [
            (3088, 2316), (2316, 3088),
            (1280, 960),  (960, 1280),
            (1920, 1440), (1440, 1920),
            (3840, 2880), (2880, 3840)
        ]
        return frontCamSizes.contains(where: { $0.0 == w && $0.1 == h })
    }
}
