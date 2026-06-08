//
//  PhotoCleanerApp.swift
//  应用入口
//

import SwiftUI

@main
struct PhotoCleanerApp: App {
    @StateObject private var photoLibrary = PhotoLibraryService()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            // RootShell 必须独立 View：要在 .preferredColorScheme 之前读 @Environment(\.colorScheme)
            // 才能拿到不被任何 override 污染的系统真实模式
            RootShell()
                .environmentObject(photoLibrary)
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .tint(AppPalette.brand)
        }
    }
}

/// 包装层：在 .preferredColorScheme 之前捕获系统真实 colorScheme，并通过自定义 environment key 注入下层
private struct RootShell: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemScheme  // 此时还没经过任何 preferredColorScheme，是真实系统值

    var body: some View {
        RootView()
            .environment(\.systemColorScheme, systemScheme)
            .preferredColorScheme(themeManager.current.colorScheme)
    }
}

// MARK: - 自定义 environment key：系统真实 colorScheme

private struct SystemColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .light
}

extension EnvironmentValues {
    /// 系统真实 colorScheme（不被任何 .preferredColorScheme override 影响）
    /// 用于 .system 主题在 sheet 内正确 resolve 背景
    var systemColorScheme: ColorScheme {
        get { self[SystemColorSchemeKey.self] }
        set { self[SystemColorSchemeKey.self] = newValue }
    }
}
