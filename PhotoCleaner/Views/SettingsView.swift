//
//  SettingsView.swift
//  设置面板：通过右上齿轮按钮或底部「更多」tab 打开
//

import SwiftUI
import Photos

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: PhotoLibraryService

    // 偏好项持久化
    @AppStorage("haptics_enabled")        private var hapticsEnabled = true
    @AppStorage("thumbnail_hq")           private var hqThumbnails = true
    @AppStorage("confirm_before_delete")  private var confirmBeforeDelete = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        brandHeader

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
                            infoRow(label: "版本", symbol: "info.circle", value: "0.4.0")
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
            .preferredColorScheme(.dark)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppPalette.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                }
            }
        }
    }

    // MARK: - 顶部品牌信息块

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
                .foregroundStyle(AppPalette.textPrimary)
            Text("整理你的照片库，腾出存储空间")
                .font(.system(size: 13))
                .foregroundStyle(AppPalette.textSecondary)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 通用 section 容器

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppPalette.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
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
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 50)
    }

    // MARK: - 行类型

    /// 开关行
    private func toggleRow(label: String, symbol: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            iconBubble(symbol, tint: AppPalette.brand)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(AppPalette.brand)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    /// 信息行（只读）
    private func infoRow(label: String, symbol: String, value: String) -> some View {
        HStack(spacing: 14) {
            iconBubble(symbol, tint: AppPalette.textSecondary)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    /// 动作行（点击触发）
    private func actionRow(label: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                iconBubble(symbol, tint: tint)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppPalette.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 外部链接行
    private func linkRow(label: String, symbol: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                iconBubble(symbol, tint: AppPalette.brand)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppPalette.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    /// 圆形图标气泡
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

    // MARK: - 底部隐私声明

    private var footerNote: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppPalette.textTertiary)
            Text("PhotoCleaner 在本地处理你的所有照片\n绝不上传任何数据")
                .font(.system(size: 11))
                .foregroundStyle(AppPalette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }
}
