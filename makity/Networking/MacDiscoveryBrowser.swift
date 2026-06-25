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
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: descriptor, using: parameters)

        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.handle(state)
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor [weak self] in
                self?.updateResults(results)
            }
        }

        self.browser = browser
        statusMessage = "Searching for Macs on local network..."
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
            statusMessage = discoveredMacs.isEmpty ? "Searching for Macs on local network..." : "Found \(discoveredMacs.count) Mac(s)"
        case .waiting(let error):
            isBrowsing = false
            statusMessage = discoveryFailureMessage(for: error)
        case .failed(let error):
            isBrowsing = false
            statusMessage = discoveryFailureMessage(for: error)
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

        if isBrowsing {
            statusMessage = discoveredMacs.isEmpty ? "Searching for Macs on local network..." : "Found \(discoveredMacs.count) Mac(s)"
        }
    }

    private func discoveryFailureMessage(for error: NWError) -> String {
        switch error {
        case .dns(let dnsError) where dnsError == kDNSServiceErr_PolicyDenied:
            return "Local Network permission denied. Enable it in iPhone Settings."
        case .posix(let posixError) where posixError == .EPERM:
            return "Local Network permission blocked. Check app privacy settings."
        default:
            return "Discovery failed: \(error.localizedDescription)"
        }
    }
}
