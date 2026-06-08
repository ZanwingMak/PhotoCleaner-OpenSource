//
//  LanguageManager.swift
//  应用内多语言：中 / 英 / 日 / 韩 / 跟随系统
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, zh, en, ja, ko

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .zh:     return "中文"
        case .en:     return "English"
        case .ja:     return "日本語"
        case .ko:     return "한국어"
        }
    }

    var flag: String {
        switch self {
        case .system: return "globe"
        case .zh:     return "character.bubble"
        case .en:     return "a.circle"
        case .ja:     return "j.circle"
        case .ko:     return "k.circle"
        }
    }

    /// 用于 DateFormatter / NumberFormatter 等系统格式化
    var localeIdentifier: String {
        switch self {
        case .system: return Locale.current.identifier
        case .zh:     return "zh-Hans"
        case .en:     return "en"
        case .ja:     return "ja"
        case .ko:     return "ko"
        }
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    @AppStorage("app_lang") private var raw: String = AppLanguage.system.rawValue

    var current: AppLanguage {
        AppLanguage(rawValue: raw) ?? .system
    }

    /// 实际使用的语言（解析 system 到具体语言）
    var effective: AppLanguage {
        if current != .system { return current }
        return Self.systemPreferredLanguage()
    }

    /// 解析系统首选语言，避免 Locale.current 被应用默认语言影响
    private static func systemPreferredLanguage() -> AppLanguage {
        let identifiers = Locale.preferredLanguages + [
            Locale.autoupdatingCurrent.identifier,
            Locale.current.identifier
        ]
        for identifier in identifiers {
            if let language = language(from: identifier) {
                return language
            }
        }
        return .zh
    }

    /// 将系统语言标识转换为应用支持的语言
    private static func language(from identifier: String) -> AppLanguage? {
        let normalized = identifier
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        if normalized.hasPrefix("zh") { return .zh }
        if normalized.hasPrefix("ja") { return .ja }
        if normalized.hasPrefix("ko") { return .ko }
        if normalized.hasPrefix("en") { return .en }
        return nil
    }

    func set(_ language: AppLanguage) {
        raw = language.rawValue
        objectWillChange.send()
    }

    /// 翻译方法：根据当前语言取词；缺失则回退到 key 本身（中文）
    func t(_ key: String) -> String {
        L10n.dict[key]?[effective] ?? key
    }
}
