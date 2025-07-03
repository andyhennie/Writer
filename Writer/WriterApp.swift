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
        .commands {
            ViewCommands()
        }
    }
}

struct ViewCommands: Commands {
    @ObservedObject private var titleBarState = TitleBarState.shared
    
    var body: some Commands {
        CommandMenu("View") {
            Toggle("Hide Title Bar", isOn: Binding(
                get: { titleBarState.isHidden },
                set: { _ in 
                    NotificationCenter.default.post(name: .toggleTitleBar, object: nil)
                }
            ))
            .keyboardShortcut("t", modifiers: .command)
        }
    }
}

class TitleBarState: ObservableObject {
    static let shared = TitleBarState()
    @Published var isHidden = false
    
    private init() {}
}

extension Notification.Name {
    static let toggleTitleBar = Notification.Name("toggleTitleBar")
}
