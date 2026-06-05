//
//  FloatingTabBar.swift
//  浮动药丸式 Tab Bar：iOS 26 厚液态玻璃 + 边缘高光 + 选中态品牌色发光
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
                // iOS 26 厚液态玻璃，带品牌色微弱 tint
                Capsule(style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular.tint(AppPalette.brand.opacity(0.05)),
                                  in: .capsule)
            } else {
                // 降级版：双层叠加营造厚玻璃感
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule().fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12),
                                         Color.white.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    }
            }
        }
        // 顶部高光环（液态玻璃感觉的关键）
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35),
                                 Color.white.opacity(0.05),
                                 Color.white.opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
        // 内阴影底部，让玻璃看起来更厚
        .overlay {
            Capsule()
                .stroke(Color.black.opacity(0.4), lineWidth: 1)
                .blur(radius: 3)
                .offset(y: 2)
                .mask {
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
        }
        .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
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
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
                    .symbolEffect(.bounce, value: isSelected)
                Text(item.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    // 选中态：暖橙渐变胶囊
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
}
