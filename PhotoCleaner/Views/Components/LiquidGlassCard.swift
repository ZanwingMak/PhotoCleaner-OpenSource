//
//  LiquidGlassCard.swift
//  iOS 26 液态玻璃容器：基于 .glassEffect 修饰器；旧系统降级到 ultraThinMaterial
//

import SwiftUI

/// 液态玻璃卡片容器，iOS 26 使用原生 glassEffect API
struct LiquidGlassCard<Content: View>: View {
    var tint: Color = .clear
    var cornerRadius: CGFloat = 28
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                if #available(iOS 26.0, *) {
                    // iOS 26 原生液态玻璃
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.clear)
                        .glassEffect(
                            .regular.tint(tint.opacity(0.18)),
                            in: .rect(cornerRadius: cornerRadius)
                        )
                } else {
                    // 降级方案：ultraThinMaterial + 边缘高光
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(0.15))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
                }
            }
    }
}

/// 浮动的玻璃药丸按钮（用于操作栏）
struct GlassPillButton: View {
    let systemImage: String
    let label: String?
    var tint: Color = .primary
    var action: () -> Void

    init(systemImage: String, label: String? = nil, tint: Color = .primary, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.label = label
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                if let label {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(tint)
            .padding(.horizontal, label == nil ? 16 : 20)
            .padding(.vertical, 14)
            .background {
                if #available(iOS 26.0, *) {
                    Capsule(style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular.interactive(), in: .capsule)
                } else {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }
}
