import SwiftUI

@main
struct MacRemoteApp: App {
    var body: some Scene {
        #if os(macOS)
        MenuBarExtra {
            MacServerView()
        } label: {
            Label("MacRemote", systemImage: "desktopcomputer")
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
