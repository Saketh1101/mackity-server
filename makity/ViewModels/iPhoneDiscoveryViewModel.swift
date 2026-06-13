import Combine
import Foundation

#if os(iOS)
@MainActor
final class PhoneDiscoveryViewModel: ObservableObject {
    @Published var discovery = MacDiscoveryBrowser()
    @Published var client = MacRemoteClient()
    @Published private(set) var selectedMac: DiscoveredMac?

    var availableMacs: [DiscoveredMac] {
        discovery.discoveredMacs
    }

    func startDiscovery() {
        discovery.start()
    }

    func stopDiscovery() {
        discovery.stop()
    }

    func connect(to mac: DiscoveredMac) {
        selectedMac = mac
        client.connect(to: mac)
    }

    func disconnect() {
        client.disconnect()
        selectedMac = nil
    }
}
#endif
