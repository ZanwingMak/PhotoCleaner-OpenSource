//
//  AppPalette.swift
//  全局色板：暖色深色为默认；主题切换由 ThemeManager 控制
//

import SwiftUI

enum AppPalette {
    /// 由全局主题决定基色
    @MainActor
    static func bgPrimary(for theme: AppTheme) -> Color {
        switch theme {
        case .system, .dark: return Color(red: 0.07, green: 0.065, blue: 0.06)
        case .light:         return Color(red: 0.97, green: 0.95, blue: 0.91)
        case .warm:          return Color(red: 0.13, green: 0.07, blue: 0.05)
        case .cool:          return Color(red: 0.06, green: 0.08, blue: 0.12)
        }
    }

    @MainActor
    static func bgCard(for theme: AppTheme) -> Color {
        switch theme {
        case .system, .dark: return Color(red: 0.11, green: 0.10, blue: 0.095)
        case .light:         return Color(red: 1.0, green: 1.0, blue: 1.0)
        case .warm:          return Color(red: 0.18, green: 0.12, blue: 0.09)
        case .cool:          return Color(red: 0.11, green: 0.13, blue: 0.18)
        }
    }

    @MainActor
    static func bgCardElevated(for theme: AppTheme) -> Color {
        switch theme {
        case .system, .dark: return Color(red: 0.15, green: 0.135, blue: 0.125)
        case .light:         return Color(red: 0.99, green: 0.98, blue: 0.95)
        case .warm:          return Color(red: 0.22, green: 0.15, blue: 0.10)
        case .cool:          return Color(red: 0.14, green: 0.17, blue: 0.22)
        }
    }

    @MainActor
    static func textPrimary(for theme: AppTheme) -> Color {
        theme == .light ? Color(red: 0.10, green: 0.10, blue: 0.10)
                        : Color(red: 0.98, green: 0.97, blue: 0.95)
    }

    @MainActor
    static func textSecondary(for theme: AppTheme) -> Color {
        theme == .light ? Color(red: 0.45, green: 0.43, blue: 0.40)
                        : Color(red: 0.62, green: 0.59, blue: 0.56)
    }

    @MainActor
    static func textTertiary(for theme: AppTheme) -> Color {
        theme == .light ? Color(red: 0.65, green: 0.63, blue: 0.60)
                        : Color(red: 0.40, green: 0.38, blue: 0.36)
    }

    // 兼容旧调用（默认深色）
    static let bgPrimary = Color(red: 0.07, green: 0.065, blue: 0.06)
    static let bgCard = Color(red: 0.11, green: 0.10, blue: 0.095)
    static let bgCardElevated = Color(red: 0.15, green: 0.135, blue: 0.125)
    static let textPrimary = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let textSecondary = Color(red: 0.62, green: 0.59, blue: 0.56)
    static let textTertiary = Color(red: 0.40, green: 0.38, blue: 0.36)

    /// 品牌色（不随主题变）
    static let brand = Color(red: 1.0, green: 0.55, blue: 0.40)
    static let brandSoft = Color(red: 1.0, green: 0.72, blue: 0.50)
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.45)
    static let success = Color(red: 0.45, green: 0.85, blue: 0.55)

    static let brandGradient = LinearGradient(
        colors: [brand, brandSoft],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
