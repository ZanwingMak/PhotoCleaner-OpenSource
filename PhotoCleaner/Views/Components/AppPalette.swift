//
//  AppPalette.swift
//  全局色板：静态属性自动跟随 ColorScheme（light/dark）切换
//  暖橙 / 冷色调等自定义主题在 RootView 通过 preferredColorScheme 映射为 light 或 dark
//

import SwiftUI
import UIKit

enum AppPalette {

    // MARK: - 主题感知颜色（系统 traitCollection 自动响应）

    /// 主背景
    static var bgPrimary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1)
                : UIColor(red: 0.07, green: 0.065, blue: 0.06, alpha: 1)
        })
    }

    /// 卡片背景
    static var bgCard: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
                : UIColor(red: 0.11, green: 0.10, blue: 0.095, alpha: 1)
        })
    }

    /// 卡片背景（升起态，强调）
    static var bgCardElevated: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(red: 1.0, green: 0.99, blue: 0.96, alpha: 1)
                : UIColor(red: 0.15, green: 0.135, blue: 0.125, alpha: 1)
        })
    }

    /// 文字主
    static var textPrimary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
                : UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1)
        })
    }

    /// 文字次
    static var textSecondary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(red: 0.40, green: 0.38, blue: 0.36, alpha: 1)
                : UIColor(red: 0.62, green: 0.59, blue: 0.56, alpha: 1)
        })
    }

    /// 文字三级
    static var textTertiary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(red: 0.55, green: 0.53, blue: 0.50, alpha: 1)
                : UIColor(red: 0.40, green: 0.38, blue: 0.36, alpha: 1)
        })
    }

    // MARK: - 品牌色（不随主题变）

    static let brand = Color(red: 1.0, green: 0.55, blue: 0.40)
    static let brandSoft = Color(red: 1.0, green: 0.72, blue: 0.50)
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.45)
    static let success = Color(red: 0.45, green: 0.85, blue: 0.55)

    static let brandGradient = LinearGradient(
        colors: [brand, brandSoft],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: - 兼容旧 API（带 for: theme 参数）— 保持现有 SettingsView 代码可用

    @MainActor
    static func bgPrimary(for theme: AppTheme) -> Color {
        switch theme {
        case .light: return bgPrimary // 走 ColorScheme = light 路径
        case .system, .dark: return bgPrimary
        case .warm: return Color(red: 0.13, green: 0.07, blue: 0.05)
        case .cool: return Color(red: 0.06, green: 0.08, blue: 0.12)
        }
    }

    @MainActor
    static func bgCard(for theme: AppTheme) -> Color {
        switch theme {
        case .light, .system, .dark: return bgCard
        case .warm: return Color(red: 0.18, green: 0.12, blue: 0.09)
        case .cool: return Color(red: 0.11, green: 0.13, blue: 0.18)
        }
    }

    @MainActor
    static func bgCardElevated(for theme: AppTheme) -> Color {
        switch theme {
        case .light, .system, .dark: return bgCardElevated
        case .warm: return Color(red: 0.22, green: 0.15, blue: 0.10)
        case .cool: return Color(red: 0.14, green: 0.17, blue: 0.22)
        }
    }

    @MainActor
    static func textPrimary(for theme: AppTheme) -> Color { textPrimary }

    @MainActor
    static func textSecondary(for theme: AppTheme) -> Color { textSecondary }

    @MainActor
    static func textTertiary(for theme: AppTheme) -> Color { textTertiary }
}
