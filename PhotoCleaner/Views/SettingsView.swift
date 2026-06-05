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

    @AppStorage("haptics_enabled")        private var hapticsEnabled = true
    @AppStorage("thumbnail_hq")           private var hqThumbnails = true
    @AppStorage("confirm_before_delete")  private var confirmBeforeDelete = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary(for: themeManager.current).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        brandHeader

                        section("外观") {
                            themePickerRow
                        }

                        section("浏览体验") {
                            toggleRow(label: "触觉反馈", symbol: "iphone.gen2.radiowaves.left.and.right",
                                       binding: $hapticsEnabled)
                            divider
                            toggleRow(label: "高清缩略图", symbol: "rectangle.stack",
                                       binding: $hqThumbnails)
                            divider
                            toggleRow(label: "删除前二次确认", symbol: "checkmark.shield",
                                       binding: $confirmBeforeDelete)
                        }

                        section("数据") {
                            infoRow(label: "已扫描照片", symbol: "photo.on.rectangle",
                                     value: "\(library.categoryCounts[PhotoCategory.allPhotos.id] ?? 0)")
                            divider
                            actionRow(label: "重新扫描分类", symbol: "arrow.clockwise",
                                       tint: AppPalette.brand) {
                                Task { await library.refreshCategoryCounts() }
                            }
                        }

                        section("关于") {
                            infoRow(label: "版本", symbol: "info.circle", value: "0.6.0")
                            divider
                            linkRow(label: "GitHub 仓库", symbol: "chevron.left.forwardslash.chevron.right",
                                     url: "https://github.com/ZanwingMak/PhotoCleaner")
                            divider
                            linkRow(label: "反馈问题", symbol: "exclamationmark.bubble",
                                     url: "https://github.com/ZanwingMak/PhotoCleaner/issues")
                            divider
                            linkRow(label: "更新日志", symbol: "list.bullet.rectangle",
                                     url: "https://github.com/ZanwingMak/PhotoCleaner/blob/main/CHANGELOG.md")
                        }

                        footerNote
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 关闭按钮：用系统 Button 样式，不再叠 Circle 背景
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .tint(AppPalette.brand)
                }
            }
        }
    }

    private var theme: AppTheme { themeManager.current }

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
            Text("整理你的照片库，腾出存储空间")
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
                Text("主题")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary(for: theme))
                Spacer()
                Text(themeManager.current.title)
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
                                isSelected ? AppPalette.brand : Color.white.opacity(0.08),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    }
                Image(systemName: t.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(t == .light ? .black : .white)
                    .opacity(0.8)
            }
            Text(t.title)
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
                            .strokeBorder(.white.opacity(0.04), lineWidth: 1)
                    )
            )
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
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
            Text("PhotoCleaner 在本地处理你的所有照片\n绝不上传任何数据")
                .font(.system(size: 11))
                .foregroundStyle(AppPalette.textTertiary(for: theme))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }
}
