import Combine
import Foundation
import Network

@MainActor
final class MacDiscoveryBrowser: ObservableObject {
    @Published private(set) var discoveredMacs: [DiscoveredMac] = []
    @Published private(set) var statusMessage = "Discovery stopped"
    @Published private(set) var isBrowsing = false

    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "MacRemote.Discovery.Browser")

    func start() {
        guard browser == nil else { return }

        let descriptor = NWBrowser.Descriptor.bonjour(type: MacRemoteService.bonjourType, domain: nil)
        let browser = NWBrowser(for: descriptor, using: .tcp)

        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handle(state)
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                self?.updateResults(results)
            }
        }

        self.browser = browser
        statusMessage = "Searching for Macs..."
        browser.start(queue: queue)
    }

    func stop() {
        browser?.cancel()
        browser = nil
        discoveredMacs = []
        isBrowsing = false
        statusMessage = "Discovery stopped"
    }

    private func handle(_ state: NWBrowser.State) {
        switch state {
        case .setup:
            statusMessage = "Preparing discovery..."
        case .ready:
            isBrowsing = true
            statusMessage = "Searching for Macs..."
        case .waiting(let error):
            isBrowsing = false
            statusMessage = "Discovery waiting: \(error.localizedDescription)"
        case .failed(let error):
            isBrowsing = false
            statusMessage = "Discovery failed: \(error.localizedDescription)"
            browser = nil
        case .cancelled:
            isBrowsing = false
            statusMessage = "Discovery stopped"
            browser = nil
        @unknown default:
            statusMessage = "Unknown discovery state"
        }
    }

    private func updateResults(_ results: Set<NWBrowser.Result>) {
        discoveredMacs = results
            .map { result in
                DiscoveredMac(name: result.endpoint.displayName, endpoint: result.endpoint)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
