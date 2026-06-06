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
            RootView()
                .environmentObject(photoLibrary)
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .preferredColorScheme(themeManager.current.colorScheme)
                .tint(AppPalette.brand)
        }
    }
}
