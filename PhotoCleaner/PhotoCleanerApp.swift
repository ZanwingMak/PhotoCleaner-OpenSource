//
//  PhotoCleanerApp.swift
//  应用入口
//

import SwiftUI

@main
struct PhotoCleanerApp: App {
    @StateObject private var photoLibrary = PhotoLibraryService()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(photoLibrary)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.current.colorScheme)
                .tint(AppPalette.brand)
        }
    }
}
