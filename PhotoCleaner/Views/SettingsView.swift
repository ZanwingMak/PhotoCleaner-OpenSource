//
//  SettingsView.swift
//  设置面板：偏好开关 + 主题切换 + 关于
//

import SwiftUI
import Photos

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: PhotoLibraryService
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var lm: LanguageManager

    @AppStorage("haptics_enabled")        private var hapticsEnabled = true
    @AppStorage("thumbnail_hq")           private var hqThumbnails = true
    @AppStorage("confirm_before_delete")  private var confirmBeforeDelete = true

    @State private var isScanning = false
    @State private var toast: ToastInfo?

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary(for: themeManager.current).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        brandHeader

                        section(lm.t("外观")) {
                            themePickerRow
                        }

                        section(lm.t("语言")) {
                            languagePickerRow
                        }

                        section(lm.t("浏览体验")) {
                            toggleRow(label: lm.t("触觉反馈"), symbol: "iphone.gen2.radiowaves.left.and.right",
                                       binding: $hapticsEnabled)
                            divider
                            toggleRow(label: lm.t("高清缩略图"), symbol: "rectangle.stack",
                                       binding: $hqThumbnails)
                            divider
                            toggleRow(label: lm.t("删除前二次确认"), symbol: "checkmark.shield",
                                       binding: $confirmBeforeDelete)
                        }

                        section(lm.t("数据")) {
                            infoRow(label: lm.t("已扫描照片"), symbol: "photo.on.rectangle",
                                     value: "\(library.categoryCounts[PhotoCategory.allPhotos.id] ?? 0)")
                            divider
                            scanRow
                        }

                        section(lm.t("关于")) {
                            infoRow(label: lm.t("版本"), symbol: "info.circle", value: appVersion)
                            divider
                            linkRow(label: lm.t("GitHub 仓库"), symbol: "chevron.left.forwardslash.chevron.right",
                                     url: "https://github.com/ZanwingMak/PhotoCleaner")
                            divider
                            linkRow(label: lm.t("反馈问题"), symbol: "exclamationmark.bubble",
                                     url: "https://github.com/ZanwingMak/PhotoCleaner/issues")
                            divider
                            linkRow(label: lm.t("更新日志"), symbol: "list.bullet.rectangle",
                                     url: "https://github.com/ZanwingMak/PhotoCleaner/blob/main/CHANGELOG.md")
                        }

                        footerNote
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .toast($toast)
            .preferredColorScheme(themeManager.current.colorScheme)
            .navigationTitle(lm.t("设置"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lm.t("关闭")) {
                        dismiss()
                    }
                    .tint(AppPalette.brand)
                }
            }
        }
        // 主题变化时让整个 NavigationStack 重建，绕过 sheet 内 traitCollection 缓存
        .id(themeManager.current.rawValue)
    }

    // MARK: - 语言选择行

    private var languagePickerRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                iconBubble("character.bubble", tint: AppPalette.brand)
                Text(lm.t("语言"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary(for: theme))
                Spacer()
                Text(lm.t(lm.current.title))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary(for: theme))
            }

            // 横向 5 个语言按钮
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            lm.set(lang)
                        } label: {
                            let isSelected = lm.current == lang
                            Text(lm.t(lang.title))
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? .white : AppPalette.textSecondary(for: theme))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background {
                                    if isSelected {
                                        Capsule().fill(AppPalette.brandGradient)
                                    } else {
                                        Capsule().fill(Color.primary.opacity(0.08))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    /// 重新扫描分类按钮 — 含 loading + 完成 toast
    private var scanRow: some View {
        Button {
            Task { await rescanWithFeedback() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppPalette.brand.opacity(0.18))
                        .frame(width: 30, height: 30)
                    if isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppPalette.brand)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppPalette.brand)
                    }
                }
                Text(isScanning ? lm.t("正在扫描…") : lm.t("重新扫描分类"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary(for: theme))
                Spacer()
                if !isScanning {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppPalette.textTertiary(for: theme))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isScanning)
    }

    /// 执行重新扫描 + 反馈
    private func rescanWithFeedback() async {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        isScanning = true
        await library.refreshCategoryCounts()
        isScanning = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            let count = library.categoryCounts[PhotoCategory.allPhotos.id] ?? 0
            toast = ToastInfo(
                symbol: "checkmark.circle.fill",
                text: String(format: lm.t("扫描完成 · %d 张"), count),
                tint: AppPalette.success
            )
        }
    }

    private var theme: AppTheme { themeManager.current }

    /// 从 Info.plist 读取当前 build 的版本号，避免硬编码
    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        if let s = short, let b = build, s != b {
            return "\(s) (\(b))"
        }
        return short ?? "—"
    }

    // MARK: - 顶部品牌头

    private var brandHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppPalette.brandGradient)
                    .frame(width: 76, height: 76)
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppPalette.brand.opacity(0.5), radius: 16, x: 0, y: 8)

            Text("PhotoCleaner")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary(for: theme))
            Text(lm.t("整理你的照片库，腾出存储空间"))
                .font(.system(size: 13))
                .foregroundStyle(AppPalette.textSecondary(for: theme))
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 主题切换行（5 个色块横向）

    private var themePickerRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                iconBubble("paintbrush.fill", tint: AppPalette.brand)
                Text(lm.t("主题"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary(for: theme))
                Spacer()
                Text(lm.t(themeManager.current.title))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary(for: theme))
            }

            HStack(spacing: 10) {
                ForEach(AppTheme.allCases) { t in
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        themeManager.set(t)
                    } label: {
                        themeSwatch(t)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    /// 单个主题色块
    private func themeSwatch(_ t: AppTheme) -> some View {
        let isSelected = themeManager.current == t
        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(t.swatch)
                    .frame(height: 52)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isSelected ? AppPalette.brand : Color.primary.opacity(0.08),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    }
                Image(systemName: t.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(t == .light ? .black : .white)
                    .opacity(0.8)
            }
            Text(lm.t(t.title))
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? AppPalette.brand
                                            : AppPalette.textSecondary(for: theme))
                .lineLimit(1)
        }
    }

    // MARK: - 通用 section

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppPalette.textSecondary(for: theme))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppPalette.bgCard(for: theme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.primary.opacity(0.04), lineWidth: 1)
                    )
            )
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 50)
    }

    // MARK: - 行类型

    private func toggleRow(label: String, symbol: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            iconBubble(symbol, tint: AppPalette.brand)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary(for: theme))
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(AppPalette.brand)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func infoRow(label: String, symbol: String, value: String) -> some View {
        HStack(spacing: 14) {
            iconBubble(symbol, tint: AppPalette.textSecondary(for: theme))
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary(for: theme))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.textSecondary(for: theme))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func actionRow(label: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                iconBubble(symbol, tint: tint)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary(for: theme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppPalette.textTertiary(for: theme))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func linkRow(label: String, symbol: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                iconBubble(symbol, tint: AppPalette.brand)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary(for: theme))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppPalette.textTertiary(for: theme))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private func iconBubble(_ symbol: String, tint: Color) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 30, height: 30)
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
        }
    }

    private var footerNote: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppPalette.textTertiary(for: theme))
            Text(lm.t("PhotoCleaner 在本地处理你的所有照片\n绝不上传任何数据"))
                .font(.system(size: 11))
                .foregroundStyle(AppPalette.textTertiary(for: theme))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }
}
