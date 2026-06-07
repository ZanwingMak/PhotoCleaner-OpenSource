//
//  ToastView.swift
//  顶部浮现的小玻璃药丸提示，2 秒自动消失
//  根据 ColorScheme 自动切换深底白字 / 白底黑字
//

import SwiftUI
import Combine

struct ToastInfo: Equatable {
    let symbol: String
    let text: String
    let tint: Color
    let id: UUID = UUID()
}

struct ToastView: View {
    let info: ToastInfo
    @Environment(\.colorScheme) private var scheme

    private var bg: Color {
        scheme == .light ? Color.white.opacity(0.95) : Color.black.opacity(0.75)
    }

    private var textColor: Color {
        scheme == .light ? Color.black : Color.white
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: info.symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(info.tint)
            Text(info.text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background {
            Capsule().fill(bg)
                .overlay(
                    Capsule().strokeBorder(
                        scheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
                )
        }
        .shadow(color: .black.opacity(scheme == .light ? 0.18 : 0.4),
                radius: 18, x: 0, y: 6)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }
}

/// Toast 容器修饰器
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastInfo?
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(info: toast)
                        .padding(.top, 8)
                        .id(toast.id)
                }
            }
            .onChange(of: toast) { _, newValue in
                guard newValue != nil else { return }
                workItem?.cancel()
                let item = DispatchWorkItem {
                    withAnimation(.easeInOut(duration: 0.3)) { toast = nil }
                }
                workItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: item)
            }
    }
}

extension View {
    func toast(_ binding: Binding<ToastInfo?>) -> some View {
        modifier(ToastModifier(toast: binding))
    }
}
