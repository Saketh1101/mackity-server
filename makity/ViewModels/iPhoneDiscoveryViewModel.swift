import Combine
import Foundation

#if os(iOS)
@MainActor
final class PhoneDiscoveryViewModel: ObservableObject {
    let discovery = MacDiscoveryBrowser()
    let client = MacRemoteClient()
    @Published private(set) var selectedMac: DiscoveredMac?

    private var cancellables: Set<AnyCancellable> = []

    var availableMacs: [DiscoveredMac] {
        discovery.discoveredMacs
    }

    init() {
        discovery.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        client.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
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
