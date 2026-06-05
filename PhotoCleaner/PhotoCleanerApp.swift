//
//  PhotoCleanerApp.swift
//  应用入口：定义 @main 启动点，初始化全局状态对象
//

import SwiftUI

@main
struct PhotoCleanerApp: App {
    // 全局照片库服务，跨视图共享授权状态与资产列表
    @StateObject private var photoLibrary = PhotoLibraryService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(photoLibrary)
                .preferredColorScheme(nil) // 自动跟随系统深浅色
        }
    }
}
