import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        MacServerView()
        #elseif os(iOS)
        PhoneDiscoveryView()
        #else
        UnsupportedPlatformView()
        #endif
    }
}

struct UnsupportedPlatformView: View {
    var body: some View {
        ContentUnavailableView(
            "Unsupported Platform",
            systemImage: "exclamationmark.triangle",
            description: Text("MacRemote Phase 1 supports macOS server and iOS client targets.")
        )
    }
}

#Preview {
    ContentView()
}
