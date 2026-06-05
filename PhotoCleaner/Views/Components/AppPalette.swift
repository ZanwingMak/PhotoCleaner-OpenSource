//
//  AppPalette.swift
//  全局色板 — 暖色深色主题，呼应 AppIcon 的橙粉调
//

import SwiftUI

enum AppPalette {
    /// 主背景：深炭，带极轻橙调
    static let bgPrimary = Color(red: 0.07, green: 0.065, blue: 0.06)
    /// 卡片背景
    static let bgCard = Color(red: 0.11, green: 0.10, blue: 0.095)
    /// 卡片背景（更亮，强调用）
    static let bgCardElevated = Color(red: 0.15, green: 0.135, blue: 0.125)

    /// 主品牌色：暖珊瑚
    static let brand = Color(red: 1.0, green: 0.55, blue: 0.40)
    /// 次强调：杏色
    static let brandSoft = Color(red: 1.0, green: 0.72, blue: 0.50)
    /// 樱红（删除）
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.45)
    /// 草绿（已整理）
    static let success = Color(red: 0.45, green: 0.85, blue: 0.55)

    /// 文字主
    static let textPrimary = Color(red: 0.98, green: 0.97, blue: 0.95)
    /// 文字次
    static let textSecondary = Color(red: 0.62, green: 0.59, blue: 0.56)
    /// 文字三级
    static let textTertiary = Color(red: 0.40, green: 0.38, blue: 0.36)

    /// 品牌渐变：暖橙到杏粉
    static let brandGradient = LinearGradient(
        colors: [brand, brandSoft],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
