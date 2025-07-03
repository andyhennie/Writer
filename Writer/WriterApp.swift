//
//  WriterApp.swift
//  Writer
//
//  Created by Andreas Hennie on 02/07/2025.
//

import SwiftUI
import SwiftData

@main
struct WriterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TextDocument.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
