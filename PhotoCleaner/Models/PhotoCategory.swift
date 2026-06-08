//
//  PhotoCategory.swift
//  照片分类定义：覆盖系统智能相册、元数据推断、按月份分组
//

import Foundation
import Photos
import SwiftUI

/// 照片分类：统一抽象快速合集、智能相册、推断分类、月份分组
enum PhotoCategory: Identifiable, Hashable {
    case allPhotos
    case quickPick(QuickPick)
    case smartAlbum(PHAssetCollectionSubtype, title: String, symbol: String, tint: Color)
    case inferred(InferredKind)
    case month(year: Int, month: Int)

    /// 横向滚动的「快速合集」：随机 / 这一天 / 去年
    enum QuickPick: String, CaseIterable, Hashable {
        case random        // 随机
        case onThisDay     // 这一天（历年今天）
        case lastYear      // 去年同期
        case thisWeek      // 本周

        var title: String {
            switch self {
            case .random:    return "随机"
            case .onThisDay: return "这一天"
            case .lastYear:  return "去年"
            case .thisWeek:  return "本周"
            }
        }

        var symbol: String {
            switch self {
            case .random:    return "shuffle"
            case .onThisDay: return "calendar.badge.clock"
            case .lastYear:  return "clock.arrow.circlepath"
            case .thisWeek:  return "calendar"
            }
        }
    }

    /// 元数据推断分类
    enum InferredKind: String, CaseIterable, Hashable {
        case allUnsorted   // 所有未整理
        case unsortedVideo // 未整理的视频
        case screenshot    // 未整理的截图
        case oldScreenshot // 陈年截图
        case selfie        // 自拍
        case camera        // 相机原图
        case social        // 社交媒体
        case lowResolution // 低清图片
        case landscape     // 横屏
        case portrait      // 竖屏
        case largeFile     // 大文件

        var title: String {
            switch self {
            case .allUnsorted:   return "所有未整理"
            case .unsortedVideo: return "未整理的视频"
            case .screenshot:    return "未整理的截图"
            case .oldScreenshot: return "陈年截图"
            case .selfie:        return "自拍"
            case .camera:        return "相机原图"
            case .social:        return "社交媒体"
            case .lowResolution: return "低清图片"
            case .landscape:     return "横屏照片"
            case .portrait:      return "竖屏照片"
            case .largeFile:     return "大文件"
            }
        }
    }

    var id: String {
        switch self {
        case .allPhotos: return "all"
        case .quickPick(let p): return "quick-\(p.rawValue)"
        case .smartAlbum(let sub, _, _, _): return Self.smartAlbumId(for: sub)
        case .inferred(let k): return "inferred-\(k.rawValue)"
        case .month(let y, let m): return "month-\(y)-\(m)"
        }
    }

    var title: String {
        switch self {
        case .allPhotos: return "全部照片"
        case .quickPick(let p): return p.title
        case .smartAlbum(_, let t, _, _): return t
        case .inferred(let k): return k.title
        case .month(let y, let m): return "\(m)月 \(y)"
        }
    }

    var symbol: String {
        switch self {
        case .allPhotos: return "photo.on.rectangle.angled"
        case .quickPick(let p): return p.symbol
        case .smartAlbum(_, _, let s, _): return s
        case .inferred(let k):
            switch k {
            case .allUnsorted:   return "tray.full"
            case .unsortedVideo: return "video"
            case .screenshot:    return "rectangle.dashed"
            case .oldScreenshot: return "calendar.badge.exclamationmark"
            case .selfie:        return "person.crop.circle"
            case .camera:        return "camera.aperture"
            case .social:        return "bubble.left.and.bubble.right"
            case .lowResolution: return "photo.badge.exclamationmark"
            case .landscape:     return "rectangle"
            case .portrait:      return "rectangle.portrait"
            case .largeFile:     return "externaldrive"
            }
        case .month: return "calendar"
        }
    }

    /// 主色：每种分类用一种柔和粉彩
    var tint: Color {
        switch self {
        case .allPhotos: return .gray
        case .quickPick(let p):
            switch p {
            case .random:    return .pink
            case .onThisDay: return .orange
            case .lastYear:  return .yellow
            case .thisWeek:  return .mint
            }
        case .smartAlbum(_, _, _, let c): return c
        case .inferred(let k):
            switch k {
            case .allUnsorted:   return .gray
            case .unsortedVideo: return .gray
            case .screenshot:    return .gray
            case .oldScreenshot: return .blue
            case .selfie:        return .pink
            case .camera:        return .orange
            case .social:        return .purple
            case .lowResolution: return .purple
            case .landscape:     return .teal
            case .portrait:      return .indigo
            case .largeFile:     return .red
            }
        case .month(_, let m):
            // 模仿参考的柔和粉彩月份配色（按月份循环）
            let pastels: [Color] = [
                Color(red: 0.78, green: 0.84, blue: 0.95), // 1 月 蓝
                Color(red: 0.82, green: 0.92, blue: 0.78), // 2 月 绿
                Color(red: 0.94, green: 0.92, blue: 0.72), // 3 月 黄
                Color(red: 0.95, green: 0.82, blue: 0.65), // 4 月 橙
                Color(red: 0.93, green: 0.78, blue: 0.82), // 5 月 粉
                Color(red: 0.78, green: 0.92, blue: 0.82), // 6 月 青
                Color(red: 0.95, green: 0.85, blue: 0.78), // 7 月 杏
                Color(red: 0.88, green: 0.82, blue: 0.95), // 8 月 淡紫
                Color(red: 0.95, green: 0.78, blue: 0.78), // 9 月 珊瑚
                Color(red: 0.85, green: 0.92, blue: 0.78), // 10 月 抹茶
                Color(red: 0.78, green: 0.88, blue: 0.95), // 11 月 冰蓝
                Color(red: 0.85, green: 0.78, blue: 0.95)  // 12 月 薰衣草
            ]
            return pastels[(m - 1).clamped(to: 0...11)]
        }
    }

    /// 主页智能分类视图（仿参考的 quick 合集 + 胶囊条）
    static var quickPicks: [PhotoCategory] {
        [
            .quickPick(.random),
            .quickPick(.thisWeek),
            .quickPick(.onThisDay),
            .quickPick(.lastYear)
        ]
    }

    /// 顶部统计胶囊条（灰色）
    static var unsortedStats: [PhotoCategory] {
        [
            .inferred(.allUnsorted),
            .inferred(.unsortedVideo),
            .inferred(.screenshot)
        ]
    }

    /// 生成系统智能相册的稳定统计 key
    static func smartAlbumId(for subtype: PHAssetCollectionSubtype) -> String {
        "smart-\(subtype.rawValue)"
    }
}

// MARK: - 工具

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
