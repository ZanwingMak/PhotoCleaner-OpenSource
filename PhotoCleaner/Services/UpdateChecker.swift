//
//  UpdateChecker.swift
//  调用 GitHub /releases/latest API 检查仓库是否发布了比当前更新的版本
//

import Foundation

/// 检查 PhotoCleaner 是否有可用更新；网络/解析失败一律静默，不打扰用户
@MainActor
final class UpdateChecker: ObservableObject {
    /// 仓库 owner / repo
    private let owner = "ZanwingMak"
    private let repo = "PhotoCleaner-OpenSource"

    /// 远端最新版本号（不含 v 前缀）
    @Published var latestVersion: String?
    /// 对应 release 的 web 页面 URL（用于点击跳转）
    @Published var releaseURL: URL?
    /// 当前是否正在请求
    @Published var isChecking = false

    /// 当前本地版本，从 Info.plist CFBundleShortVersionString 取
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }

    /// 是否存在比当前更新的发布版
    var hasUpdate: Bool {
        guard let latest = latestVersion else { return false }
        return compare(latest, currentVersion) == .orderedDescending
    }

    /// 触发一次检查；同一时刻只允许一个请求在飞
    func check() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest") else {
            return
        }
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let payload = try JSONDecoder().decode(GHRelease.self, from: data)
            latestVersion = payload.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
            releaseURL = URL(string: payload.html_url)
        } catch {
            // 静默：网络断开 / API 限流 / 仓库无 release 都不弹错误
        }
    }

    /// GitHub releases API 响应裁剪
    private struct GHRelease: Decodable {
        let tag_name: String
        let html_url: String
    }

    /// 语义版本字符串按段比较：1.1.10 > 1.1.9
    private func compare(_ a: String, _ b: String) -> ComparisonResult {
        let ap = a.split(separator: ".").compactMap { Int($0) }
        let bp = b.split(separator: ".").compactMap { Int($0) }
        let n = max(ap.count, bp.count)
        for i in 0..<n {
            let av = i < ap.count ? ap[i] : 0
            let bv = i < bp.count ? bp[i] : 0
            if av > bv { return .orderedDescending }
            if av < bv { return .orderedAscending }
        }
        return .orderedSame
    }
}
