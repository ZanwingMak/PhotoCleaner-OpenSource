//
//  RootView.swift
//  入口分发：根据授权状态展示引导页或主界面
//

import SwiftUI
import Photos

struct RootView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch library.authorizationStatus {
            case .authorized, .limited:
                CategoryListView()
            case .denied, .restricted:
                PermissionDeniedView()
            case .notDetermined:
                PermissionView()
            @unknown default:
                PermissionView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: library.authorizationStatus)
        .task {
            // 启动时主动调一次 requestAuthorization，TCC 已 grant 时不会弹窗直接返回
            if library.authorizationStatus == .notDetermined {
                await library.requestAuthorization()
            } else {
                library.refreshAuthorizationStatus()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                library.refreshAuthorizationStatus()
            }
        }
    }
}

/// 首次启动：解释为什么需要权限，再请求
struct PermissionView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.08), Color.purple.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // 图标
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                VStack(spacing: 12) {
                    Text(lm.t("整理你的照片库"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(lm.t("快速滑动审核每张照片，腾出存储空间。\n所有删除操作都需要你手动确认。"))
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                Button {
                    Task { await library.requestAuthorization() }
                } label: {
                    Text(lm.t("允许访问照片"))
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            if #available(iOS 26.0, *) {
                                Capsule().fill(.clear).glassEffect(.regular.tint(.blue.opacity(0.35)).interactive(), in: .capsule)
                            } else {
                                Capsule().fill(Color.blue)
                            }
                        }
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}

/// 用户拒绝授权时的引导
struct PermissionDeniedView: View {
    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(lm.t("无法访问照片"))
                .font(.title2.weight(.semibold))
            Text(lm.t("请在「设置 → 隐私与安全性 → 照片」中允许 RollKeep 访问。"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(lm.t("打开设置"))
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Capsule().fill(.tint.opacity(0.15)))
            }
            .padding(.top, 8)
        }
        .padding()
    }
}
