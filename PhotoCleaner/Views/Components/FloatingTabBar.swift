//
//  FloatingTabBar.swift
//  仿参考的浮动药丸式 Tab Bar（液态玻璃）
//

import SwiftUI

/// Tab Bar 上的 4 个目的地（当前实现只有「整理」可用，其它为占位）
enum TabBarItem: String, CaseIterable, Identifiable {
    case organize = "未整理"
    case photos   = "照片"
    case albums   = "相簿"
    case more     = "更多"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .organize: return "rectangle.portrait.on.rectangle.portrait"
        case .photos:   return "square.grid.2x2.fill"
        case .albums:   return "square.stack.fill"
        case .more:     return "line.3.horizontal"
        }
    }
}

/// 浮动 tab bar：液态玻璃药丸 + 选中项白色高亮胶囊
struct FloatingTabBar: View {
    let selected: TabBarItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabBarItem.allCases) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background {
            if #available(iOS 26.0, *) {
                Capsule(style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: .capsule)
            } else {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
    }

    /// 单个 tab 按钮
    @ViewBuilder
    private func tabButton(_ item: TabBarItem) -> some View {
        let isSelected = (item == selected)
        VStack(spacing: 3) {
            Image(systemName: item.symbol)
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            Text(item.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.12))
            }
        }
    }
}
