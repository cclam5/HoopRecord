//
//  hoopkitApp.swift
//  hoopkit
//
//  Created by CC . on 2024/12/30.
//

import SwiftUI

@main
struct hoopkitApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
