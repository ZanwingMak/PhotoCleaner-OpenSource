//
//  ThemeManager.swift
//  主题管理：跟随系统 / 强制深色 / 强制浅色 / 暖色 / 冷色
//

import SwiftUI

/// 用户可选主题
enum AppTheme: String, CaseIterable, Identifiable {
    case system  // 跟随系统
    case dark    // 深色（默认暖橙调）
    case light   // 浅色（米白）
    case warm    // 暖色（焦糖深棕）
    case cool    // 冷色（深蓝灰）

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .dark:   return "深色"
        case .light:  return "浅色"
        case .warm:   return "焦糖暖"
        case .cool:   return "冷色调"
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .dark:   return "moon.fill"
        case .light:  return "sun.max.fill"
        case .warm:   return "flame.fill"
        case .cool:   return "drop.fill"
        }
    }

    var swatch: Color {
        switch self {
        case .system: return Color(red: 0.50, green: 0.50, blue: 0.50)
        case .dark:   return Color(red: 0.11, green: 0.10, blue: 0.095)
        case .light:  return Color(red: 0.97, green: 0.95, blue: 0.91)
        case .warm:   return Color(red: 0.20, green: 0.10, blue: 0.07)
        case .cool:   return Color(red: 0.10, green: 0.12, blue: 0.16)
        }
    }

    /// 转换为 SwiftUI ColorScheme（nil 表示跟随系统）
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark, .warm, .cool: return .dark
        }
    }
}

/// 全局主题管理器，持久化用户选择
@MainActor
final class ThemeManager: ObservableObject {
    @AppStorage("app_theme") private var raw: String = AppTheme.dark.rawValue

    var current: AppTheme {
        get { AppTheme(rawValue: raw) ?? .dark }
        set { raw = newValue.rawValue; objectWillChange.send() }
    }

    func set(_ theme: AppTheme) {
        current = theme
    }
}
