//
//  FloatingTabBar.swift
//  浮动药丸式 Tab Bar：跟随 ColorScheme 切换浅/深主题，未选中文字用 .secondary 自动适配
//

import SwiftUI

enum TabBarItem: String, CaseIterable, Identifiable {
    case organize = "整理"
    case photos   = "照片"
    case albums   = "相簿"
    case more     = "更多"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .organize: return "sparkles.rectangle.stack.fill"
        case .photos:   return "photo.fill.on.rectangle.fill"
        case .albums:   return "square.stack.fill"
        case .more:     return "square.grid.2x2.fill"
        }
    }
}

struct FloatingTabBar: View {
    let selected: TabBarItem
    let onTap: (TabBarItem) -> Void
    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TabBarItem.allCases) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background {
            if #available(iOS 26.0, *) {
                Capsule(style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular.tint(AppPalette.brand.opacity(0.05)),
                                  in: .capsule)
            } else {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule().fill(
                            LinearGradient(
                                colors: [
                                    Color.primary.opacity(scheme == .light ? 0.04 : 0.12),
                                    Color.primary.opacity(0.02)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    }
            }
        }
        // 顶部高光环
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(scheme == .light ? 0.15 : 0.35),
                            Color.primary.opacity(0.05),
                            Color.primary.opacity(0.15)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
        .shadow(color: .black.opacity(scheme == .light ? 0.18 : 0.5),
                radius: 24, x: 0, y: 12)
        .shadow(color: AppPalette.brand.opacity(0.12), radius: 18, x: 0, y: 0)
    }

    @ViewBuilder
    private func tabButton(_ item: TabBarItem) -> some View {
        let isSelected = (item == selected)
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            onTap(item)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(iconColor(isSelected: isSelected))
                    .symbolEffect(.bounce, value: isSelected)
                Text(lm.t(item.rawValue))
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(iconColor(isSelected: isSelected))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(AppPalette.brandGradient)
                        .overlay {
                            Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1)
                        }
                        .shadow(color: AppPalette.brand.opacity(0.45),
                                radius: 10, x: 0, y: 4)
                }
            }
            .contentShape(Rectangle())
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    /// 选中态在彩色 brand 渐变上始终用白色；未选中用 .secondary 自动适配明暗
    private func iconColor(isSelected: Bool) -> Color {
        if isSelected { return .white }
        return Color.secondary
    }
}
