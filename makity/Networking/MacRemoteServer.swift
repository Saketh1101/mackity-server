import Combine
import Foundation
import Network

@MainActor
final class MacRemoteServer: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var statusMessage = "Server stopped"
    @Published private(set) var connectedClientCount = 0
    @Published private(set) var lastReceivedMessage: RemoteMessage?
    @Published private(set) var streamingStatusMessage = "Screen stream stopped"
    @Published private(set) var accessibilityStatusMessage = "Accessibility permission not requested"
    @Published private(set) var availableDisplayCount = 1

    private var listener: NWListener?
    private var connections: [UUID: RemoteConnection] = [:]
    private let listenerQueue = DispatchQueue(label: "MacRemote.Server.Listener")
    private let remoteControlService = RemoteControlService()
    private var cancellables: Set<AnyCancellable> = []
    private var currentDisplayIndex = 0

    #if os(macOS)
    private let screenStreamingService = ScreenStreamingService()
    #endif

    init() {
        #if os(macOS)
        screenStreamingService.onFrame = { [weak self] message in
            self?.broadcast(message)
        }

        screenStreamingService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.availableDisplayCount = self?.screenStreamingService.availableDisplayCount ?? 1
            }
            .store(in: &cancellables)
        #endif
    }

    func start(deviceName: String) {
        guard listener == nil else { return }

        do {
            let listener = try NWListener(using: .tcp)
            listener.service = NWListener.Service(name: deviceName, type: MacRemoteService.bonjourType)

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    self?.handleListenerState(state)
                }
            }

            listener.newConnectionHandler = { [weak self] nwConnection in
                Task { @MainActor [weak self] in
                    self?.accept(nwConnection)
                }
            }

            self.listener = listener
            statusMessage = "Starting server..."
            listener.start(queue: listenerQueue)
        } catch {
            statusMessage = "Server failed: \(error.localizedDescription)"
            isRunning = false
            listener = nil
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        connections.values.forEach { $0.cancel() }
        connections.removeAll()
        connectedClientCount = 0
        isRunning = false
        statusMessage = "Server stopped"

        #if os(macOS)
        Task { @MainActor in
            await screenStreamingService.stop()
            streamingStatusMessage = screenStreamingService.statusMessage
        }
        #endif
    }

    func send(_ message: RemoteMessage, to connectionID: UUID) {
        connections[connectionID]?.send(message)
    }

    func requestAccessibilityPermission() {
        #if os(macOS)
        remoteControlService.requestAccessibilityPermission()
        accessibilityStatusMessage = remoteControlService.accessibilityStatusMessage
        #endif
    }

    func switchDisplay(to index: Int) {
        currentDisplayIndex = index
        #if os(macOS)
        if isRunning, !connections.isEmpty {
            Task { @MainActor in
                let config = ScreenStreamingConfiguration(
                    framesPerSecond: 15,
                    maximumWidth: 1280,
                    jpegQuality: 0.55,
                    displayIndex: index
                )
                await screenStreamingService.start(configuration: config)
                streamingStatusMessage = screenStreamingService.statusMessage
            }
        }
        #endif
    }

    private func broadcast(_ message: RemoteMessage) {
        connections.values.forEach { $0.send(message) }
    }

    private func accept(_ nwConnection: NWConnection) {
        let remoteConnection = RemoteConnection(connection: nwConnection)
        connections[remoteConnection.id] = remoteConnection
        connectedClientCount = connections.count
        statusMessage = "Client connected"

        remoteConnection.onStateChange = { [weak self, weak remoteConnection] state in
            guard let remoteConnection else { return }
            Task { @MainActor in
                self?.handleConnectionState(state, connectionID: remoteConnection.id)
            }
        }

        remoteConnection.onMessage = { [weak self, weak remoteConnection] message in
            guard let remoteConnection else { return }
            Task { @MainActor in
                self?.handle(message, from: remoteConnection.id)
            }
        }

        remoteConnection.onError = { [weak self] error in
            Task { @MainActor in
                self?.statusMessage = "Connection error: \(error.localizedDescription)"
            }
        }

        remoteConnection.start()
    }

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .setup:
            statusMessage = "Preparing server..."
        case .waiting(let error):
            isRunning = false
            statusMessage = "Server waiting: \(error.localizedDescription)"
        case .ready:
            isRunning = true
            statusMessage = "Server running"
        case .failed(let error):
            isRunning = false
            statusMessage = "Server failed: \(error.localizedDescription)"
            listener = nil
        case .cancelled:
            isRunning = false
            statusMessage = "Server stopped"
            listener = nil
        @unknown default:
            statusMessage = "Unknown server state"
        }
    }

    private func handleConnectionState(_ state: NWConnection.State, connectionID: UUID) {
        switch state {
        case .failed, .cancelled:
            connections.removeValue(forKey: connectionID)
            connectedClientCount = connections.count
            statusMessage = isRunning ? "Server running" : "Server stopped"

            if connections.isEmpty {
                #if os(macOS)
                Task { @MainActor in
                    await screenStreamingService.stop()
                    streamingStatusMessage = screenStreamingService.statusMessage
                }
                #endif
            }
        default:
            break
        }
    }

    private func handle(_ message: RemoteMessage, from connectionID: UUID) {
        lastReceivedMessage = message

        if message.type == .screenshotRequest {
            startScreenStreaming(for: message.screenshotRequest)
        }

        let responses = remoteControlService.handle(message)
        #if os(macOS)
        accessibilityStatusMessage = remoteControlService.accessibilityStatusMessage
        #endif
        responses.forEach { send($0, to: connectionID) }
    }

    private func startScreenStreaming(for request: ScreenshotRequestPayload?) {
        #if os(macOS)
        Task { @MainActor in
            let config = ScreenStreamingConfiguration(request: request)
            await screenStreamingService.start(configuration: config)
            streamingStatusMessage = screenStreamingService.statusMessage
            availableDisplayCount = screenStreamingService.availableDisplayCount
        }
        #endif
    }
}
