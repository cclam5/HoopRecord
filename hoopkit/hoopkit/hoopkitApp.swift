//
//  hoopkitApp.swift
//  hoopkit
//
//  Created by CC . on 2024/12/30.
//

import SwiftUI

@main
struct HoopKitApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
