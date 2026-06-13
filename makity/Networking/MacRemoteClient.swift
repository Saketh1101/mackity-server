import Combine
import Foundation
import Network

@MainActor
final class MacRemoteClient: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var statusMessage = "Not connected"
    @Published private(set) var lastReceivedMessage: RemoteMessage?

    private var connection: RemoteConnection?

    func connect(to mac: DiscoveredMac) {
        disconnect()

        let connection = RemoteConnection(endpoint: mac.endpoint)
        self.connection = connection
        statusMessage = "Connecting to \(mac.name)..."

        connection.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.handle(state, macName: mac.name)
            }
        }

        connection.onMessage = { [weak self] message in
            Task { @MainActor in
                self?.lastReceivedMessage = message
            }
        }

        connection.onError = { [weak self] error in
            Task { @MainActor in
                self?.statusMessage = "Connection error: \(error.localizedDescription)"
            }
        }

        connection.start()
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
        statusMessage = "Not connected"
    }

    func send(_ message: RemoteMessage) {
        connection?.send(message)
    }

    func ping() {
        send(.ping)
    }

    private func handle(_ state: NWConnection.State, macName: String) {
        switch state {
        case .setup, .preparing:
            isConnected = false
            statusMessage = "Connecting to \(macName)..."
        case .ready:
            isConnected = true
            statusMessage = "Connected to \(macName)"
            send(.ping)
        case .waiting(let error):
            isConnected = false
            statusMessage = "Waiting: \(error.localizedDescription)"
        case .failed(let error):
            isConnected = false
            statusMessage = "Connection failed: \(error.localizedDescription)"
            connection = nil
        case .cancelled:
            isConnected = false
            statusMessage = "Not connected"
            connection = nil
        @unknown default:
            statusMessage = "Unknown connection state"
        }
    }
}
