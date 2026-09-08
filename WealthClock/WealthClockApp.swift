import SwiftData
import SwiftUI

@main
struct WealthClockApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if CommandLine.arguments.contains("-gallery") {
                GalleryView()
            } else if CommandLine.arguments.contains("-reveal") {
                RevealView()
            } else if CommandLine.arguments.contains("-bill") {
                BillScreen()
            } else if CommandLine.arguments.contains("-quiz") {
                QuizView()
            } else if CommandLine.arguments.contains("-history") {
                RootTabView(initialTab: .history)
            } else {
                RootTabView()
            }
            #else
            RootTabView()
            #endif
        }
        .modelContainer(for: Reading.self)
    }
}
