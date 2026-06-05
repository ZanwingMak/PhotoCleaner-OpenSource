//
//  ToastView.swift
//  顶部浮现的小玻璃药丸提示，2 秒自动消失
//

import SwiftUI
import Combine

/// Toast 数据
struct ToastInfo: Equatable {
    let symbol: String
    let text: String
    let tint: Color
    let id: UUID = UUID()
}

/// 顶部浮现的玻璃药丸 toast
struct ToastView: View {
    let info: ToastInfo

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: info.symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(info.tint)
            Text(info.text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background {
            if #available(iOS 26.0, *) {
                Capsule().fill(.clear).glassEffect(.regular, in: .capsule)
            } else {
                Capsule().fill(.ultraThinMaterial)
                    .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }
}

/// Toast 容器修饰器：附在任意 View 上即可弹 toast
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastInfo?
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(info: toast)
                        .padding(.top, 8)
                        .id(toast.id) // 不同 id 触发动画
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
    /// 给视图挂上 toast 能力
    func toast(_ binding: Binding<ToastInfo?>) -> some View {
        modifier(ToastModifier(toast: binding))
    }
}
