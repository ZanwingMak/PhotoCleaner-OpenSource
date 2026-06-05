//
//  PhotoLibraryService.swift
//  PhotosKit 封装：授权、按分类查、按月份聚合、加载缩略图、批量删除
//

import Foundation
import Photos
import UIKit
import Combine

/// 月份分组数据
struct MonthBucket: Identifiable, Hashable {
    let year: Int
    let month: Int
    let count: Int
    var id: String { "\(year)-\(month)" }
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
    }

    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.authorizationStatus = status
    }

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
            let all = arrayFrom(PHAsset.fetchAssets(with: options))
            return all.filter { PhotoClassifier.matches($0, kind: kind) }

        case .quickPick(let pick):
            let all = arrayFrom(PHAsset.fetchAssets(with: options))
            if pick == .random {
                return Array(all.shuffled().prefix(200))
            }
            return all.filter { PhotoClassifier.matches($0, quick: pick) }

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
        isLoading = true
        defer { isLoading = false }

        // 1. 统计推断分类的数量（这些是首页主要展示的）
        var counts: [String: Int] = [:]

        let all = arrayFrom(PHAsset.fetchAssets(with: defaultSort()))
        counts[PhotoCategory.allPhotos.id] = all.count

        for kind in PhotoCategory.InferredKind.allCases {
            let n = all.filter { PhotoClassifier.matches($0, kind: kind) }.count
            counts[PhotoCategory.inferred(kind).id] = n
        }

        // 2. quickPicks 数量
        for pick in PhotoCategory.QuickPick.allCases {
            if pick == .random {
                counts[PhotoCategory.quickPick(pick).id] = min(all.count, 200)
            } else {
                let n = all.filter { PhotoClassifier.matches($0, quick: pick) }.count
                counts[PhotoCategory.quickPick(pick).id] = n
            }
        }

        // 3. 按月份分桶（仅近 24 个月）
        let cal = Calendar.current
        var bucketMap: [String: (year: Int, month: Int, count: Int)] = [:]
        for asset in all {
            guard let date = asset.creationDate else { continue }
            let y = cal.component(.year, from: date)
            let m = cal.component(.month, from: date)
            let key = "\(y)-\(m)"
            bucketMap[key, default: (y, m, 0)].count += 1
        }
        let sorted = bucketMap.values
            .map { MonthBucket(year: $0.year, month: $0.month, count: $0.count) }
            .sorted { ($0.year, $0.month) > ($1.year, $1.month) }

        self.categoryCounts = counts
        self.monthBuckets = Array(sorted.prefix(24))
    }

    /// 加载缩略图
    @discardableResult
    func loadImage(
        for asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
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

    private func defaultSort() -> PHFetchOptions {
        let o = PHFetchOptions()
        o.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return o
    }

    private func arrayFrom(_ result: PHFetchResult<PHAsset>) -> [PHAsset] {
        var arr: [PHAsset] = []
        arr.reserveCapacity(result.count)
        result.enumerateObjects { obj, _, _ in arr.append(obj) }
        return arr
    }
}
