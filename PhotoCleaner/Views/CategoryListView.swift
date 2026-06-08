//
//  CategoryListView.swift
//  首页 — PhotoCleaner 自有风格：
//  Hero 大数字 + 智能建议 + Bento 网格 + 月份时间线，暖色深色调
//

import SwiftUI
import Photos

private enum TopTab: String, CaseIterable {
    case unsorted
    case albums
}

struct CategoryListView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @EnvironmentObject private var lm: LanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var topTab: TopTab = .unsorted
    @State private var tabBarItem: TabBarItem = .organize
    @State private var toast: ToastInfo?
    @State private var showSettings = false
    @State private var showPhotosBrowser = false
    @State private var showSuggestionList = false
    @State private var visibleMonthCount = 24

    /// 刷新按钮持续旋转角度
    @State private var refreshSpinAngle: Double = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                backgroundLayer

                // 顶部固定 header（greeting + segmented）保证两个 tab 位置一致
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 14) {
                        topGreetingBar
                        segmentedTabs
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                    // 内容区
                    Group {
                        switch topTab {
                        case .unsorted: unsortedScroll
                        case .albums:   albumsScroll
                        }
                    }
                    .transition(.opacity)
                }

                FloatingTabBar(selected: tabBarItem) { item in
                    handleTabBarTap(item)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
            }
            .toast($toast)
            
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: PhotoCategory.self) { category in
                SwipeReviewView(category: category)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPhotosBrowser) {
                PhotosBrowserView()
            }
            .sheet(isPresented: $showSuggestionList) {
                SmartSuggestionListSheet()
            }
            .task {
                if library.categoryCounts.isEmpty {
                    await library.refreshCategoryCounts()
                }
            }
        }
    }

    // MARK: - 背景：暖橙径向光晕 + 深炭底

    private var backgroundLayer: some View {
        ZStack {
            AppPalette.bgPrimary(for: themeManager.current).ignoresSafeArea()
            // 右上角暖光
            RadialGradient(
                colors: [AppPalette.brand.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 30, endRadius: 380
            )
            .ignoresSafeArea()
            .blendMode(.plusLighter)
            // 左下角粉光
            RadialGradient(
                colors: [AppPalette.danger.opacity(0.12), .clear],
                center: .bottomLeading,
                startRadius: 30, endRadius: 380
            )
            .ignoresSafeArea()
            .blendMode(.plusLighter)
        }
    }

    // MARK: - 「整理」滚动页

    private var unsortedScroll: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                heroStorageCard
                smartSuggestionRow
                quickPickRow
                bentoCategoryGrid
                monthlyTimeline
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .refreshable { // 下拉刷新（Safari 风）
            await library.refreshCategoryCounts()
            showRefreshToast()
        }
    }

    // MARK: - 「相簿」滚动页（保留极简列表）

    private var albumsScroll: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(albumRows, id: \.id) { category in
                    NavigationLink(value: category) {
                        AlbumRow(category: category, count: library.categoryCounts[category.id])
                    }
                    .buttonStyle(.plain)
                    Rectangle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(height: 1)
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .refreshable {
            await library.refreshCategoryCounts()
            showRefreshToast()
        }
    }

    /// 刷新完成弹 toast
    private func showRefreshToast() {
        let count = library.categoryCounts[PhotoCategory.allPhotos.id] ?? 0
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            toast = ToastInfo(
                symbol: "checkmark.circle.fill",
                text: String(format: lm.t("刷新成功 · %d 张"), count),
                tint: AppPalette.success
            )
        }
    }

    private var albumRows: [PhotoCategory] {
        [
            .allPhotos,
            .smartAlbum(.smartAlbumFavorites, title: "收藏", symbol: "heart.fill", tint: .red),
            .smartAlbum(.smartAlbumVideos, title: "视频", symbol: "video.fill", tint: .green),
            .smartAlbum(.smartAlbumLivePhotos, title: "实况照片", symbol: "livephoto", tint: .mint),
            .smartAlbum(.smartAlbumRecentlyAdded, title: "最近添加", symbol: "clock.fill", tint: .yellow),
            .inferred(.selfie), .inferred(.camera), .inferred(.social),
            .inferred(.largeFile), .inferred(.landscape), .inferred(.portrait)
        ]
    }

    // MARK: - 顶部问候 + 右侧设置

    private var topGreetingBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lm.t(greetingHello))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
                Text("PhotoCleaner")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)
            }
            Spacer()
            // 刷新按钮：点击立即转一圈，isLoading 期间继续累加，完成弹 toast
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.easeOut(duration: 0.6)) {
                    refreshSpinAngle += 360
                }
                Task {
                    await library.refreshCategoryCounts()
                    showRefreshToast()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(Color.primary.opacity(0.06))
                            .overlay(Circle().strokeBorder(.primary.opacity(0.06), lineWidth: 1))
                    )
                    .contentShape(Rectangle())
                    .rotationEffect(.degrees(refreshSpinAngle))
                    .animation(.linear(duration: 0.6), value: refreshSpinAngle)
            }
            .buttonStyle(.plain)
            .disabled(library.isLoading)
            .onReceive(Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()) { _ in
                if library.isLoading {
                    refreshSpinAngle += 360
                }
            }
            // 设置入口
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(Color.primary.opacity(0.06))
                            .overlay(Circle().strokeBorder(.primary.opacity(0.06), lineWidth: 1))
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// 按时段问候语
    private var greetingHello: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<11:  return "早上好"
        case 11..<14: return "中午好"
        case 14..<18: return "下午好"
        case 18..<23: return "晚上好"
        default:      return "夜深了"
        }
    }

    // MARK: - segmented tabs（紧凑下划线版）

    private var segmentedTabs: some View {
        HStack(spacing: 24) {
            ForEach(TopTab.allCases, id: \.rawValue) { tab in
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        topTab = tab
                        tabBarItem = (tab == .unsorted) ? .organize : .albums
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(lm.t(tab == .unsorted ? "整理" : "相簿"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(topTab == tab ? AppPalette.textPrimary : AppPalette.textSecondary)
                        Capsule()
                            .fill(topTab == tab ? AppPalette.brand : Color.clear)
                            .frame(width: 24, height: 3)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Hero 卡：可释放空间 + 环形进度

    private var heroStorageCard: some View {
        ZStack {
            // 卡片背景：跟随主题
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppPalette.bgCardElevated(for: themeManager.current))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppPalette.brandGradient.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                }

            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(lm.t("潜在可释放"))
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(AppPalette.brand)

                    // 大字号容量
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(estimatedReleaseSize)
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)
                        Text(estimatedReleaseUnit)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textSecondary)
                            .padding(.bottom, 4)
                    }

                    // 副标
                    Text(String(format: lm.t("基于 %d 张照片估算"), suggestedCleanupCount))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppPalette.textTertiary)
                }

                Spacer()

                // 环形进度
                ZStack {
                    RingProgress(value: progressValue, lineWidth: 8)
                    VStack(spacing: 0) {
                        Text("\(progressPercent)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)
                        Text("%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppPalette.textSecondary)
                            .offset(y: -2)
                    }
                }
                .frame(width: 82, height: 82)
            }
            .padding(20)
        }
        .frame(minHeight: 140)
    }

    /// 估算可释放空间：按建议清理照片平均 1.5MB/张估算
    private var estimatedReleaseSize: String {
        let bytes = Double(suggestedCleanupCount) * 1_500_000.0
        if bytes >= 1_073_741_824 {
            return String(format: "%.1f", bytes / 1_073_741_824)
        }
        return String(format: "%.0f", bytes / 1_048_576)
    }

    private var estimatedReleaseUnit: String {
        let bytes = Double(suggestedCleanupCount) * 1_500_000.0
        return bytes >= 1_073_741_824 ? "GB" : "MB"
    }

    private var totalCount: Int {
        library.categoryCounts[PhotoCategory.allPhotos.id] ?? 0
    }

    private var suggestedCleanupCount: Int {
        let raw = smartSuggestionConfigs.reduce(0) { sum, config in
            sum + (library.categoryCounts[config.category.id] ?? 0)
        }
        return min(totalCount, raw)
    }

    /// 环形进度：建议清理数量 / 全库数量
    private var progressValue: Double {
        guard totalCount > 0, suggestedCleanupCount > 0 else { return 0 }
        return max(0.01, min(1, Double(suggestedCleanupCount) / Double(totalCount)))
    }

    private var progressPercent: Int {
        guard totalCount > 0, suggestedCleanupCount > 0 else { return 0 }
        return max(1, min(100, Int((Double(suggestedCleanupCount) / Double(totalCount) * 100).rounded())))
    }

    // MARK: - 智能建议横向滚动卡（PhotoCleaner 特色，多个清理切入点）

    private var smartSuggestionRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行：左侧标题 + 右侧「更多」入口
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lm.t("智能建议"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)
                    Text(lm.t("先清这些最划算"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                }
                Spacer()
                // 「更多」按钮：点击弹出完整列表
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    showSuggestionList = true
                } label: {
                    HStack(spacing: 4) {
                        Text(lm.t("更多"))
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppPalette.brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(AppPalette.brand.opacity(0.14))
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(smartSuggestionConfigs) { cfg in
                        suggestionCard(for: cfg.category,
                                        label: cfg.label,
                                        symbol: cfg.symbol,
                                        gradient: cfg.gradient)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    /// 智能建议卡的工厂方法：避免重复代码
    @ViewBuilder
    private func suggestionCard(
        for category: PhotoCategory,
        label: String,
        symbol: String,
        gradient: [Color]
    ) -> some View {
        NavigationLink(value: category) {
            SuggestionCard(
                symbol: symbol,
                label: lm.t(label),
                count: library.categoryCounts[category.id] ?? 0,
                tint: .white,
                background: LinearGradient(colors: gradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing)
            )
            .frame(width: 170)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 横向 Quick Pick

    private var quickPickRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(lm.t("时间游戏"), subtitle: lm.t("换个角度看你的相册"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PhotoCategory.quickPicks) { cat in
                        NavigationLink(value: cat) {
                            QuickPickCard(category: cat,
                                          count: library.categoryCounts[cat.id])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Bento Grid 不规则分类网格

    private var bentoCategoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(lm.t("分类"), subtitle: nil)

            // 不规则网格：用两列，部分卡片高，部分卡片矮
            HStack(alignment: .top, spacing: 12) {
                // 左列
                VStack(spacing: 12) {
                    bentoCard(.inferred(.selfie), height: 130, accentSymbol: "person.crop.circle")
                    bentoCard(.inferred(.unsortedVideo), height: 170, accentSymbol: "video.fill")
                    bentoCard(.inferred(.social), height: 130, accentSymbol: "bubble.left.fill")
                }
                // 右列
                VStack(spacing: 12) {
                    bentoCard(.inferred(.camera), height: 170, accentSymbol: "camera.aperture")
                    bentoCard(.inferred(.landscape), height: 130, accentSymbol: "rectangle")
                    bentoCard(.inferred(.portrait), height: 130, accentSymbol: "rectangle.portrait")
                }
            }
        }
    }

    /// Bento 单卡
    private func bentoCard(_ category: PhotoCategory, height: CGFloat, accentSymbol: String) -> some View {
        NavigationLink(value: category) {
            BentoCard(category: category,
                      count: library.categoryCounts[category.id],
                      height: height,
                      accentSymbol: accentSymbol)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 月份时间线

    private var monthlyTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            timelineTitle

            LazyVStack(spacing: 0) {
                ForEach(Array(displayedMonthBuckets.enumerated()), id: \.element.id) { idx, bucket in
                    let cat = PhotoCategory.month(year: bucket.year, month: bucket.month)
                    NavigationLink(value: cat) {
                        TimelineRow(
                            month: bucket.month,
                            year: bucket.year,
                            count: bucket.count,
                            tint: cat.tint,
                            isLast: idx == displayedMonthBuckets.count - 1 && !hasMoreMonthBuckets
                        )
                    }
                    .buttonStyle(.plain)
                }

                if hasMoreMonthBuckets {
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            loadMoreMonthBuckets()
                        }
                }
            }
        }
    }

    private var timelineTitle: some View {
        HStack(alignment: .firstTextBaseline) {
            sectionTitle(lm.t("时间线"), subtitle: lm.t("按月份回顾"))

            Spacer()

            if hasMoreMonthBuckets {
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showAllMonthBuckets()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(lm.t("显示全部"))
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppPalette.brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppPalette.brand.opacity(0.14)))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var displayedMonthBuckets: [MonthBucket] {
        Array(library.monthBuckets.prefix(visibleMonthCount))
    }

    private var hasMoreMonthBuckets: Bool {
        visibleMonthCount < library.monthBuckets.count
    }

    /// 滚动到底部时追加展示更早月份
    private func loadMoreMonthBuckets() {
        guard hasMoreMonthBuckets else { return }
        visibleMonthCount = min(library.monthBuckets.count, visibleMonthCount + 12)
    }

    /// 一次性展开全部月份时间线
    private func showAllMonthBuckets() {
        visibleMonthCount = library.monthBuckets.count
    }

    // MARK: - 通用 section title

    private func sectionTitle(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
            }
        }
    }

    // MARK: - tab bar 点击

    private func handleTabBarTap(_ item: TabBarItem) {
        switch item {
        case .organize:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                tabBarItem = .organize
                topTab = .unsorted
            }
        case .albums:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                tabBarItem = .albums
                topTab = .albums
            }
        case .photos:
            // 点击照片只弹 sheet，不改变 tabBarItem（关闭后 sheet 应回到原 tab 高亮）
            showPhotosBrowser = true
        case .more:
            // 同上，弹 sheet 不动 tabBarItem
            showSettings = true
        }
    }
}

// MARK: - 智能建议卡

private struct SuggestionCard: View {
    @EnvironmentObject private var lm: LanguageManager
    let symbol: String
    let label: String
    let count: Int
    let tint: Color
    let background: LinearGradient

    var body: some View {
        ZStack(alignment: .topTrailing) {
            background

            // 大图标做装饰，偏右下
            Image(systemName: symbol)
                .font(.system(size: 90, weight: .bold))
                .foregroundStyle(.white.opacity(0.1))
                .offset(x: 28, y: 28)

            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(lm.t("张"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右上角箭头
            Image(systemName: "arrow.up.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .padding(8)
                .background(Circle().fill(.white.opacity(0.18)))
                .padding(12)
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - 横向 Quick Pick 卡

private struct QuickPickCard: View {
    @EnvironmentObject private var lm: LanguageManager
    let category: PhotoCategory
    let count: Int?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)

            // 右上角图标
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: category.symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(10)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(lm.t(category.title))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                if let count {
                    Text("\(count) \(lm.t("张"))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(12)
        }
        .frame(width: 130, height: 110)
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

// MARK: - Bento 单卡（不规则网格成员）

private struct BentoCard: View {
    @EnvironmentObject private var lm: LanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    let category: PhotoCategory
    let count: Int?
    let height: CGFloat
    let accentSymbol: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.bgCard(for: themeManager.current))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
                }

            // 右下角大装饰图标
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: accentSymbol)
                        .font(.system(size: height * 0.55, weight: .bold))
                        .foregroundStyle(category.tint.opacity(0.18))
                        .offset(x: 14, y: 14)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                // 小图标
                ZStack {
                    Circle().fill(category.tint.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: accentSymbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(category.tint)
                }

                Spacer(minLength: 0)

                Text(lm.t(category.title))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .lineLimit(1)

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(count ?? 0)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)
                    Text(lm.t("张"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppPalette.textTertiary)
                }
            }
            .padding(14)
        }
        .frame(height: height)
    }
}

// MARK: - 月份时间线一行

private struct TimelineRow: View {
    @EnvironmentObject private var lm: LanguageManager
    let month: Int
    let year: Int
    let count: Int
    let tint: Color
    let isLast: Bool

    var body: some View {
        HStack(spacing: 14) {
            // 时间标记圆点 + 连接线
            VStack(spacing: 0) {
                Circle()
                    .fill(tint)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))

                if !isLast {
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 1.5)
                        .frame(minHeight: 32)
                }
            }
            .frame(width: 16)

            // 月份名（按当前语言本地化）
            VStack(alignment: .leading, spacing: 2) {
                Text(monthDisplay)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)
                Text("\(year)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppPalette.textTertiary)
            }
            .frame(width: 60, alignment: .leading)

            // 数量条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.05))
                        .frame(height: 8)

                    Capsule().fill(tint.opacity(0.85))
                        .frame(width: max(8, geo.size.width * countRatio), height: 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 12)

            // 数量
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }

    /// 数量条占比（参考值：1000 张 = 满）
    private var countRatio: Double {
        min(1.0, Double(count) / 1000.0)
    }

    /// 月份本地化显示：中文 / 日文 = "6月"；英文 = "Jun"；韩文 = "6월"
    private var monthDisplay: String {
        var comp = DateComponents()
        comp.year = year; comp.month = month
        guard let date = Calendar.current.date(from: comp) else {
            return "\(month)"
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: lm.effective.localeIdentifier)
        f.setLocalizedDateFormatFromTemplate("MMM")
        return f.string(from: date)
    }
}

// MARK: - 相簿一行（简版）

private struct AlbumRow: View {
    @EnvironmentObject private var lm: LanguageManager
    let category: PhotoCategory
    let count: Int?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(category.tint.opacity(0.16))
                    .frame(width: 36, height: 36)
                Image(systemName: category.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(category.tint)
            }

            Text(lm.t(category.title))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary)

            Spacer()

            if let count {
                Text("\(count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppPalette.textTertiary)
        }
        .padding(.vertical, 14)
        // 让整行（含 Spacer 区域）都参与 hit testing
        .contentShape(Rectangle())
    }
}

// MARK: - 智能建议数据源（首页横向卡 + 「更多」列表共用）

/// 智能建议条目配置
private struct SmartSuggestionConfig: Identifiable {
    let category: PhotoCategory
    let label: String
    let symbol: String
    let gradient: [Color]
    var id: String { category.id }
}

/// 智能建议数据源
private let smartSuggestionConfigs: [SmartSuggestionConfig] = [
    .init(category: .inferred(.oldScreenshot), label: "陈年截图", symbol: "calendar.badge.exclamationmark",
          gradient: [Color(red: 0.25, green: 0.45, blue: 0.85), Color(red: 0.15, green: 0.30, blue: 0.55)]),
    .init(category: .inferred(.largeFile), label: "占空间大户", symbol: "externaldrive.badge.exclamationmark",
          gradient: [Color(red: 0.85, green: 0.35, blue: 0.42), Color(red: 0.55, green: 0.20, blue: 0.30)]),
    .init(category: .smartAlbum(.smartAlbumVideos, title: "视频", symbol: "video.fill", tint: .green),
          label: "视频清理", symbol: "video.fill",
          gradient: [Color(red: 0.40, green: 0.75, blue: 0.55), Color(red: 0.20, green: 0.50, blue: 0.40)]),
    .init(category: .smartAlbum(.smartAlbumLivePhotos, title: "实况照片", symbol: "livephoto", tint: .mint),
          label: "实况照片", symbol: "livephoto",
          gradient: [Color(red: 0.30, green: 0.65, blue: 0.75), Color(red: 0.15, green: 0.40, blue: 0.55)]),
    .init(category: .smartAlbum(.smartAlbumSelfPortraits, title: "自拍", symbol: "person.crop.circle", tint: .pink),
          label: "自拍清理", symbol: "person.crop.circle",
          gradient: [Color(red: 0.95, green: 0.55, blue: 0.70), Color(red: 0.60, green: 0.30, blue: 0.55)]),
    .init(category: .inferred(.lowResolution), label: "低清图片", symbol: "photo.badge.exclamationmark",
          gradient: [Color(red: 0.65, green: 0.50, blue: 0.90), Color(red: 0.35, green: 0.25, blue: 0.65)])
]

// MARK: - 智能建议「更多」列表 sheet

/// 点击首页「更多」弹出，展示全部智能建议；点击任一项推进到滑动审核
private struct SmartSuggestionListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: PhotoLibraryService
    @EnvironmentObject private var lm: LanguageManager
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary(for: themeManager.current).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(smartSuggestionConfigs) { cfg in
                            NavigationLink(value: cfg.category) {
                                SuggestionListRow(
                                    symbol: cfg.symbol,
                                    label: lm.t(cfg.label),
                                    count: library.categoryCounts[cfg.category.id] ?? 0,
                                    gradient: LinearGradient(colors: cfg.gradient,
                                                              startPoint: .topLeading,
                                                              endPoint: .bottomTrailing)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(lm.t("智能建议"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lm.t("关闭")) { dismiss() }
                        .tint(AppPalette.brand)
                }
            }
            .navigationDestination(for: PhotoCategory.self) { cat in
                SwipeReviewView(category: cat)
            }
        }
    }
}

// MARK: - 智能建议「更多」列表行

/// 列表形式呈现的智能建议行：渐变图标 + 标题 + 数量 + 箭头
private struct SuggestionListRow: View {
    @EnvironmentObject private var lm: LanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    let symbol: String
    let label: String
    let count: Int
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(gradient)
                    .frame(width: 52, height: 52)
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textSecondary)
                    Text(lm.t("张"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppPalette.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppPalette.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.bgCard(for: themeManager.current))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
}
