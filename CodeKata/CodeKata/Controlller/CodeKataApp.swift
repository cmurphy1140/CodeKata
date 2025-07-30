//
//  CodeKataApp.swift
//  CodeKata
//
//  Created by Connor A Murphy on 7/30/25.
//
import SwiftUI
import SwiftData


@main
struct CodeKataApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Challenge.self,
            UserProgress.self
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
