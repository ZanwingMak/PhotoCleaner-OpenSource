//
//  CustomDialog.swift
//  自定义 alert 弹窗：手动控制宽度（max 360pt 比系统宽）和按钮颜色
//  避免 confirmationDialog/alert 被 app .tint 染成橙色看不清
//

import SwiftUI

struct DialogAction: Identifiable {
    let id = UUID()
    let title: String
    let role: ActionRole
    let action: () -> Void

    enum ActionRole {
        case primary    // 主操作：蓝色
        case destructive // 危险：红色
        case cancel     // 取消：灰色加粗
        case normal     // 普通：灰色
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
            // 模糊遮罩，点击关闭
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

                // 分隔线
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)

                // 按钮组（垂直排列，等宽）
                VStack(spacing: 0) {
                    ForEach(Array(actions.enumerated()), id: \.element.id) { idx, act in
                        Button {
                            act.action()
                        } label: {
                            Text(act.title)
                                .font(.system(size: 16, weight: act.role == .cancel ? .semibold : .regular))
                                .foregroundStyle(color(for: act.role))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if idx < actions.count - 1 {
                            Rectangle()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(scheme == .light ? Color.white : Color(red: 0.16, green: 0.15, blue: 0.14))
            )
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

    /// 按钮颜色：不受 app .tint 影响
    private func color(for role: DialogAction.ActionRole) -> Color {
        switch role {
        case .primary:     return Color(red: 0.0, green: 0.48, blue: 1.0)  // system blue
        case .destructive: return Color(red: 1.0, green: 0.23, blue: 0.19) // system red
        case .cancel:      return Color(red: 0.0, green: 0.48, blue: 1.0)  // system blue 加粗
        case .normal:      return Color.primary.opacity(0.85)
        }
    }
}

// MARK: - View modifier

extension View {
    /// 弹自定义 dialog；isPresented = true 时叠加显示
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
