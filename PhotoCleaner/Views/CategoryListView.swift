//
//  CategoryListView.swift
//  首页：仿 Slidebox 设计 — 大标题 + segmented + 横向 quick + 灰胶囊统计 + 月份分组
//

import SwiftUI
import Photos

/// 顶部 Tab：未整理 / 相簿
private enum TopTab: String, CaseIterable {
    case unsorted = "未整理"
    case albums   = "相簿"
}

struct CategoryListView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @State private var topTab: TopTab = .unsorted

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 全屏黑底（参考是 pure black）
                Color.black.ignoresSafeArea()

                Group {
                    switch topTab {
                    case .unsorted: unsortedScroll
                    case .albums:   albumsScroll
                    }
                }

                // 底部浮动 Tab Bar
                FloatingTabBar(selected: .organize)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
            }
            .preferredColorScheme(.dark)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { EmptyView() }
            }
            .navigationDestination(for: PhotoCategory.self) { category in
                SwipeReviewView(category: category)
            }
            .task {
                if library.categoryCounts.isEmpty {
                    await library.refreshCategoryCounts()
                }
            }
        }
    }

    // MARK: - 「未整理」滚动页

    private var unsortedScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                segmentedControl

                // 横向 quick pick 卡片
                quickPickRow

                // 「最近」section
                sectionTitle("最近")
                heroCard

                // 灰色胶囊统计条
                statsPills

                // 月份彩色胶囊
                monthlyPills

                // 底部 tab bar 留白
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    // MARK: - 「相簿」列表页

    private var albumsScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                segmentedControl
                    .padding(.bottom, 12)

                // 推断分类作为「相簿」列表
                ForEach(albumRows, id: \.id) { category in
                    NavigationLink(value: category) {
                        AlbumRow(category: category, count: library.categoryCounts[category.id])
                    }
                    .buttonStyle(.plain)
                    Divider().background(Color.white.opacity(0.05))
                }

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private var albumRows: [PhotoCategory] {
        [
            .allPhotos,
            .smartAlbum(.smartAlbumFavorites, title: "收藏", symbol: "heart.fill", tint: .red),
            .smartAlbum(.smartAlbumVideos, title: "视频", symbol: "video.fill", tint: .green),
            .smartAlbum(.smartAlbumLivePhotos, title: "实况照片", symbol: "livephoto", tint: .mint),
            .smartAlbum(.smartAlbumRecentlyAdded, title: "最近添加", symbol: "clock.fill", tint: .yellow),
            .inferred(.selfie),
            .inferred(.camera),
            .inferred(.social),
            .inferred(.largeFile),
            .inferred(.landscape),
            .inferred(.portrait)
        ]
    }

    // MARK: - 顶部标题 + 黄色提示点

    private var header: some View {
        HStack(alignment: .center) {
            Text("整理")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            // 黄色提示徽标
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.95))
                    .frame(width: 26, height: 26)
                Text("!")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.black.opacity(0.75))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - segmented control（药丸式：选中白底黑字，未选中透明白字）

    private var segmentedControl: some View {
        HStack(spacing: 8) {
            ForEach(TopTab.allCases, id: \.rawValue) { tab in
                Button {
                    let g = UIImpactFeedbackGenerator(style: .soft); g.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        topTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(topTab == tab ? .black : .white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background {
                            if topTab == tab {
                                Capsule().fill(Color.white)
                            } else {
                                Capsule().fill(Color.white.opacity(0.08))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - section 标题

    private func sectionTitle(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
    }

    // MARK: - 横向 quick pick 卡片

    private var quickPickRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PhotoCategory.quickPicks) { cat in
                    NavigationLink(value: cat) {
                        QuickPickCard(category: cat, count: library.categoryCounts[cat.id])
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - hero 卡片（本周）

    private var heroCard: some View {
        let weekCat = PhotoCategory.quickPick(.thisWeek)
        return NavigationLink(value: weekCat) {
            ZStack(alignment: .bottomLeading) {
                // 渐变占位（真实场景从最新一张照片缩略图取色）
                LinearGradient(
                    colors: [Color.pink.opacity(0.5), Color.purple.opacity(0.4), Color.blue.opacity(0.35)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text("本周")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(20)
                    .shadow(color: .black.opacity(0.4), radius: 4)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 灰色胶囊统计条

    private var statsPills: some View {
        VStack(spacing: 10) {
            ForEach(PhotoCategory.unsortedStats) { cat in
                NavigationLink(value: cat) {
                    StatPill(
                        title: cat.title,
                        count: library.categoryCounts[cat.id] ?? 0,
                        tint: Color.white.opacity(0.16),
                        textColor: .white
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 月份彩色胶囊

    private var monthlyPills: some View {
        VStack(spacing: 10) {
            ForEach(library.monthBuckets) { bucket in
                let cat = PhotoCategory.month(year: bucket.year, month: bucket.month)
                NavigationLink(value: cat) {
                    StatPill(
                        title: cat.title,
                        count: bucket.count,
                        tint: cat.tint,
                        textColor: Color.black.opacity(0.7)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 横向 quick pick 卡片

private struct QuickPickCard: View {
    let category: PhotoCategory
    let count: Int?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景渐变（仿参考的「随机」卡）
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // 顶部右上角图标淡入装饰
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: category.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(10)
                }
                Spacer()
            }

            Text(category.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(14)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
        }
        .frame(width: 160, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var gradientColors: [Color] {
        switch category {
        case .quickPick(.random):    return [Color(red: 0.95, green: 0.45, blue: 0.65), Color(red: 0.4, green: 0.3, blue: 0.65)]
        case .quickPick(.thisWeek):  return [Color(red: 0.4, green: 0.75, blue: 0.65), Color(red: 0.2, green: 0.45, blue: 0.55)]
        case .quickPick(.onThisDay): return [Color(red: 0.95, green: 0.7, blue: 0.4), Color(red: 0.7, green: 0.4, blue: 0.25)]
        case .quickPick(.lastYear):  return [Color(red: 0.7, green: 0.55, blue: 0.9), Color(red: 0.35, green: 0.3, blue: 0.55)]
        default:                     return [.gray.opacity(0.5), .gray.opacity(0.3)]
        }
    }
}

// MARK: - 胶囊统计条（统一灰色 / 彩色月份）

private struct StatPill: View {
    let title: String
    let count: Int
    let tint: Color
    let textColor: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textColor)
            Spacer()
            Text(formatCount(count))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textColor.opacity(0.85))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            Capsule(style: .continuous).fill(tint)
        )
    }

    /// 千分位格式
    private func formatCount(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - 相簿 Tab 的一行

private struct AlbumRow: View {
    let category: PhotoCategory
    let count: Int?

    var body: some View {
        HStack(spacing: 14) {
            // 描边方框图标
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Color.white.opacity(0.7), lineWidth: 1.5)
                .frame(width: 26, height: 22)

            Text(category.title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            if let count {
                Text("\(count)")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(.vertical, 16)
    }
}
