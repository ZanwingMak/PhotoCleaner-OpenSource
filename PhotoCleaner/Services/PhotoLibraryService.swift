//
//  PhotoLibraryService.swift
//  PhotosKit 封装：授权、按分类查、按月份聚合、加载缩略图、批量删除
//

import Foundation
import Photos
import UIKit
import Combine

/// 月份分组数据
struct MonthBucket: Identifiable, Hashable, Sendable {
    let year: Int
    let month: Int
    let count: Int
    var id: String { "\(year)-\(month)" }
}

/// 首页统计快照：只保存轻量计数，避免跨线程传递 PHAsset 数组
private struct PhotoLibrarySnapshot: Sendable {
    let categoryCounts: [String: Int]
    let monthBuckets: [MonthBucket]
}

@MainActor
final class PhotoLibraryService: ObservableObject {

    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false

    /// 各分类资产计数缓存
    @Published var categoryCounts: [String: Int] = [:]
    /// 按月份分桶
    @Published var monthBuckets: [MonthBucket] = []

    private let imageManager = PHCachingImageManager()

    init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.imageManager.allowsCachingHighQualityImages = false
    }

    /// 请求照片库授权并同步到页面状态
    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.authorizationStatus = status
    }

    /// 主动同步系统授权状态（用于 app 重新激活时刷新）
    func refreshAuthorizationStatus() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// 当前授权是否允许读取照片库
    var hasAccess: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    /// 取分类下所有资产
    func fetchAssets(for category: PhotoCategory) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        switch category {
        case .allPhotos:
            return arrayFrom(PHAsset.fetchAssets(with: options))

        case .smartAlbum(let subtype, _, _, _):
            let collections = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum, subtype: subtype, options: nil)
            var all: [PHAsset] = []
            collections.enumerateObjects { col, _, _ in
                all.append(contentsOf: self.arrayFrom(PHAsset.fetchAssets(in: col, options: options)))
            }
            return all

        case .inferred(let kind):
            return filteredAssets(from: PHAsset.fetchAssets(with: options)) {
                PhotoClassifier.matchesForLibraryScan($0, kind: kind)
            }

        case .quickPick(let pick):
            let result = PHAsset.fetchAssets(with: options)
            if pick == .random {
                return randomSample(from: result, limit: 200)
            }
            return filteredAssets(from: result) {
                PhotoClassifier.matches($0, quick: pick)
            }

        case .month(let y, let m):
            let cal = Calendar.current
            var start = DateComponents()
            start.year = y; start.month = m; start.day = 1
            guard let startDate = cal.date(from: start),
                  let endDate = cal.date(byAdding: .month, value: 1, to: startDate)
            else { return [] }
            let pred = NSPredicate(format: "creationDate >= %@ AND creationDate < %@",
                                   startDate as NSDate, endDate as NSDate)
            options.predicate = pred
            return arrayFrom(PHAsset.fetchAssets(with: options))
        }
    }

    /// 刷新分类计数 + 月份分桶
    func refreshCategoryCounts() async {
        guard hasAccess, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        let snapshot = await Self.buildCategorySnapshot()
        self.categoryCounts = snapshot.categoryCounts
        self.monthBuckets = snapshot.monthBuckets
    }

    /// 加载缩略图
    @discardableResult
    func loadImage(
        for asset: PHAsset,
        targetSize: CGSize,
        deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic,
        isNetworkAccessAllowed: Bool = true,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = deliveryMode
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.isSynchronous = false

        return imageManager.requestImage(
            for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options
        ) { image, _ in
            DispatchQueue.main.async { completion(image) }
        }
    }

    func cancelImageRequest(_ id: PHImageRequestID) {
        imageManager.cancelImageRequest(id)
    }

    /// 异步加载 Live Photo
    @discardableResult
    func loadLivePhoto(
        for asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (PHLivePhoto?) -> Void
    ) -> PHImageRequestID {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return imageManager.requestLivePhoto(
            for: asset, targetSize: targetSize,
            contentMode: .aspectFit, options: options
        ) { livePhoto, _ in
            DispatchQueue.main.async { completion(livePhoto) }
        }
    }

    /// 批量删除（系统弹原生确认）
    func deleteAssets(_ assets: [PHAsset]) async -> Bool {
        guard !assets.isEmpty else { return true }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    // MARK: - Helpers

    /// 在后台线程构建首页统计，避免照片多时阻塞首屏渲染
    private nonisolated static func buildCategorySnapshot() async -> PhotoLibrarySnapshot {
        await Task.detached(priority: .utility) {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let result = PHAsset.fetchAssets(with: options)
            return makeSnapshot(from: result)
        }.value
    }

    /// 单次枚举 PHFetchResult 生成所有首页计数，避免反复过滤全相册
    private nonisolated static func makeSnapshot(from result: PHFetchResult<PHAsset>) -> PhotoLibrarySnapshot {
        let now = Date()
        let cal = Calendar.current
        var counts: [String: Int] = [:]
        var bucketMap: [String: (year: Int, month: Int, count: Int)] = [:]

        counts[PhotoCategory.allPhotos.id] = result.count
        for kind in PhotoCategory.InferredKind.allCases {
            counts[PhotoCategory.inferred(kind).id] = 0
        }
        for pick in PhotoCategory.QuickPick.allCases {
            counts[PhotoCategory.quickPick(pick).id] = 0
        }
        counts[PhotoCategory.inferred(.allUnsorted).id] = result.count
        counts[PhotoCategory.quickPick(.random).id] = min(result.count, 200)
        for subtype in smartAlbumSubtypesForCounting() {
            counts[PhotoCategory.smartAlbumId(for: subtype)] = countAssets(inSmartAlbum: subtype)
        }

        result.enumerateObjects { asset, _, _ in
            autoreleasepool {
                for kind in PhotoCategory.InferredKind.allCases where kind != .allUnsorted {
                    if PhotoClassifier.matchesForLibraryScan(asset, kind: kind) {
                        counts[PhotoCategory.inferred(kind).id, default: 0] += 1
                    }
                }

                for pick in PhotoCategory.QuickPick.allCases where pick != .random {
                    if PhotoClassifier.matches(asset, quick: pick, now: now) {
                        counts[PhotoCategory.quickPick(pick).id, default: 0] += 1
                    }
                }

                guard let date = asset.creationDate else { return }
                let year = cal.component(.year, from: date)
                let month = cal.component(.month, from: date)
                let key = "\(year)-\(month)"
                bucketMap[key, default: (year, month, 0)].count += 1
            }
        }

        let buckets = bucketMap.values
            .map { MonthBucket(year: $0.year, month: $0.month, count: $0.count) }
            .sorted { ($0.year, $0.month) > ($1.year, $1.month) }

        return PhotoLibrarySnapshot(categoryCounts: counts,
                                    monthBuckets: buckets)
    }

    /// 返回首页和智能建议需要展示数量的系统智能相册
    private nonisolated static func smartAlbumSubtypesForCounting() -> [PHAssetCollectionSubtype] {
        [
            .smartAlbumFavorites,
            .smartAlbumVideos,
            .smartAlbumLivePhotos,
            .smartAlbumSelfPortraits,
            .smartAlbumRecentlyAdded
        ]
    }

    /// 读取系统智能相册数量，让首页数字与点进去后的列表保持一致
    private nonisolated static func countAssets(inSmartAlbum subtype: PHAssetCollectionSubtype) -> Int {
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: subtype,
            options: nil
        )
        var count = 0
        collections.enumerateObjects { collection, _, _ in
            count += PHAsset.fetchAssets(in: collection, options: nil).count
        }
        return count
    }

    /// 将 PHFetchResult 转成数组，仅用于确实需要完整列表的页面
    private func arrayFrom(_ result: PHFetchResult<PHAsset>) -> [PHAsset] {
        var arr: [PHAsset] = []
        arr.reserveCapacity(result.count)
        result.enumerateObjects { obj, _, _ in arr.append(obj) }
        return arr
    }

    /// 单次枚举并只保留匹配资产，避免先构建全量数组再过滤
    private func filteredAssets(
        from result: PHFetchResult<PHAsset>,
        where matches: @escaping (PHAsset) -> Bool
    ) -> [PHAsset] {
        var arr: [PHAsset] = []
        result.enumerateObjects { obj, _, _ in
            if matches(obj) {
                arr.append(obj)
            }
        }
        return arr
    }

    /// 对 PHFetchResult 做蓄水池抽样，避免随机分类全量 shuffle 占用大量内存
    private func randomSample(from result: PHFetchResult<PHAsset>, limit: Int) -> [PHAsset] {
        guard limit > 0 else { return [] }
        var sample: [PHAsset] = []
        sample.reserveCapacity(min(result.count, limit))

        result.enumerateObjects { obj, idx, _ in
            if idx < limit {
                sample.append(obj)
            } else {
                let replaceIndex = Int.random(in: 0...idx)
                if replaceIndex < limit {
                    sample[replaceIndex] = obj
                }
            }
        }

        return sample
    }
}
