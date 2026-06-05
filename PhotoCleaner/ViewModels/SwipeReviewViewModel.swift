//
//  SwipeReviewViewModel.swift
//  滑动审核视图的状态机：前后翻页（左/右滑）+ 上滑加入待删除
//

import Foundation
import Photos
import SwiftUI

/// 用户对当前卡片的处置：导航或标记
enum SwipeAction: Hashable {
    case next       // 右滑：进到下一张
    case previous   // 左滑：退到前一张
    case markDelete // 上滑：加入待删除并前进
}

/// 历史记录（只记录 markDelete，用于撤销；prev/next 无需记录因为可直接反向滑）
struct SwipeRecord: Hashable {
    let asset: PHAsset
    let fromIndex: Int
}

@MainActor
final class SwipeReviewViewModel: ObservableObject {

    @Published var assets: [PHAsset]
    @Published var currentIndex: Int = 0
    @Published var pendingDeletion: [PHAsset] = []
    @Published var deleteHistory: [SwipeRecord] = []

    /// 是否还有当前可显示的照片
    var hasMore: Bool { currentIndex < assets.count }

    /// 当前照片
    var currentAsset: PHAsset? {
        guard hasMore else { return nil }
        return assets[currentIndex]
    }

    /// 是否可向前翻页
    var canGoPrevious: Bool { currentIndex > 0 }

    /// 是否可向后翻页
    var canGoNext: Bool { currentIndex < assets.count - 1 }

    init(assets: [PHAsset]) {
        self.assets = assets
    }

    /// 处理一次滑动操作
    func handle(_ action: SwipeAction) {
        guard !assets.isEmpty else { return }

        switch action {
        case .previous:
            guard canGoPrevious else { return }
            currentIndex -= 1

        case .next:
            guard canGoNext else { return }
            currentIndex += 1

        case .markDelete:
            guard hasMore else { return }
            let asset = assets[currentIndex]
            deleteHistory.append(SwipeRecord(asset: asset, fromIndex: currentIndex))
            pendingDeletion.append(asset)
            currentIndex = min(currentIndex + 1, assets.count)
        }
    }

    /// 撤销最近一次 markDelete
    func undoLastDelete() {
        guard let last = deleteHistory.popLast() else { return }
        currentIndex = last.fromIndex
        if let removeIdx = pendingDeletion.firstIndex(where: { $0.localIdentifier == last.asset.localIdentifier }) {
            pendingDeletion.remove(at: removeIdx)
        }
    }

    /// 删除成功后清理状态
    func clearAfterDelete() {
        let deletedIds = Set(pendingDeletion.map { $0.localIdentifier })
        pendingDeletion.removeAll()
        deleteHistory.removeAll()
        assets.removeAll { deletedIds.contains($0.localIdentifier) }
        currentIndex = min(currentIndex, max(assets.count - 1, 0))
    }
}
