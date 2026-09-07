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
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}
