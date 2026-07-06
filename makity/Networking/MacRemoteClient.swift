import Combine
import Foundation
import Network

@MainActor
final class MacRemoteClient: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var statusMessage = "Not connected"
    @Published private(set) var lastReceivedMessage: RemoteMessage?
    @Published private(set) var isReconnecting = false

    private var connection: RemoteConnection?
    private var currentConnectionID: UUID?
    private var lastConnectedMac: DiscoveredMac?
    private var shouldAutoReconnect = false
    private var reconnectTask: Task<Void, Never>?

    func connect(to mac: DiscoveredMac) {
        reconnectTask?.cancel()
        reconnectTask = nil
        connection?.cancel()
        connection = nil

        lastConnectedMac = mac
        shouldAutoReconnect = true
        isConnected = false
        isReconnecting = false
        statusMessage = "Connecting to \(mac.name)..."

        let newConnection = RemoteConnection(endpoint: mac.endpoint)
        let connectionID = newConnection.id
        currentConnectionID = connectionID
        connection = newConnection

        newConnection.onStateChange = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self, self.currentConnectionID == connectionID else { return }
                self.handle(state, mac: mac)
            }
        }

        newConnection.onMessage = { [weak self] message in
            Task { @MainActor [weak self] in
                guard let self, self.currentConnectionID == connectionID else { return }
                self.lastReceivedMessage = message
            }
        }

        newConnection.onError = { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self, self.currentConnectionID == connectionID else { return }
                self.statusMessage = "Connection error: \(error.localizedDescription)"
            }
        }

        newConnection.start()
    }

    func disconnect() {
        shouldAutoReconnect = false
        isReconnecting = false
        reconnectTask?.cancel()
        reconnectTask = nil
        currentConnectionID = nil
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

    private func handle(_ state: NWConnection.State, mac: DiscoveredMac) {
        switch state {
        case .setup, .preparing:
            isConnected = false
            statusMessage = "Connecting to \(mac.name)..."

        case .ready:
            isConnected = true
            isReconnecting = false
            statusMessage = "Connected to \(mac.name)"
            send(.ping)

        case .waiting(let error):
            isConnected = false
            statusMessage = "Waiting: \(error.localizedDescription)"

        case .failed:
            isConnected = false
            connection = nil
            if shouldAutoReconnect {
                isReconnecting = true
                statusMessage = "Reconnecting to \(mac.name)..."
                scheduleReconnect(to: mac)
            } else {
                isReconnecting = false
                statusMessage = "Connection lost"
            }

        case .cancelled:
            isConnected = false
            connection = nil
            // Cancelled is triggered by an explicit disconnect or new connect — don't auto-reconnect.

        @unknown default:
            statusMessage = "Unknown connection state"
        }
    }

    private func scheduleReconnect(to mac: DiscoveredMac) {
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.connect(to: mac)
        }
    }
}
