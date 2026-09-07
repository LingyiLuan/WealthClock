import SwiftUI

@main
struct WealthClockApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if CommandLine.arguments.contains("-gallery") {
                GalleryView()
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}
