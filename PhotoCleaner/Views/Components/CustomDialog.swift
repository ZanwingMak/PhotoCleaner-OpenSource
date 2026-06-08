//
//  CustomDialog.swift
//  自定义 alert 弹窗：手动控制宽度和按钮颜色
//  浅色主题用纯白卡片；深色主题用液态玻璃背景
//

import SwiftUI

struct DialogAction: Identifiable {
    let id = UUID()
    let title: String
    let role: ActionRole
    let action: () -> Void

    enum ActionRole {
        case primary           // 主操作：蓝色文字
        case destructive       // 危险：红色文字
        case cancel            // 普通 cancel：蓝色文字加粗
        case highlightedCancel // 强调 cancel：填充背景（浅蓝底白字 / 浅深白底黑字）
        case normal            // 普通：灰色文字
    }
}

struct CustomDialog: View {
    let title: String
    let message: String
    let actions: [DialogAction]
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // 半透明遮罩，点击关闭
            (scheme == .light ? Color.black.opacity(0.35) : Color.black.opacity(0.55))
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            // 卡片
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)
                    .padding(.horizontal, 22)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)

                // 按钮组
                VStack(spacing: 0) {
                    ForEach(Array(actions.enumerated()), id: \.element.id) { idx, act in
                        actionButton(act)

                        if idx < actions.count - 1 {
                            Rectangle()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .background(dialogBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 14)
            .frame(maxWidth: 360)
            .padding(.horizontal, 18)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }

    /// 卡片背景：浅色 = 纯白；深色 = 透明液态玻璃
    @ViewBuilder
    private var dialogBackground: some View {
        if scheme == .light {
            Color.white
        } else {
            if #available(iOS 26.0, *) {
                Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 18))
            } else {
                // 真正透明的液态玻璃，不再叠半透明深色让玻璃感清晰
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }

    /// 所有按钮都用纯文字样式，无填充背景
    @ViewBuilder
    private func actionButton(_ act: DialogAction) -> some View {
        Button {
            act.action()
        } label: {
            Text(act.title)
                .font(.system(size: 16, weight: act.role == .cancel || act.role == .highlightedCancel ? .semibold : .regular))
                .foregroundStyle(color(for: act.role))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 按钮文字颜色（不受 app .tint 影响）
    /// highlightedCancel：浅色黑字 / 深色白字（在弹窗 bg 上高对比）
    private func color(for role: DialogAction.ActionRole) -> Color {
        switch role {
        case .primary:     return Color(red: 0.0, green: 0.48, blue: 1.0)
        case .destructive: return Color(red: 1.0, green: 0.23, blue: 0.19)
        case .cancel:      return Color(red: 0.0, green: 0.48, blue: 1.0)
        case .normal:      return Color.primary.opacity(0.85)
        case .highlightedCancel:
            return scheme == .light ? .black : .white
        }
    }
}

// MARK: - View modifier

extension View {
    func customDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        actions: [DialogAction]
    ) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                CustomDialog(
                    title: title,
                    message: message,
                    actions: actions,
                    onDismiss: { isPresented.wrappedValue = false }
                )
                .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
    }
}
