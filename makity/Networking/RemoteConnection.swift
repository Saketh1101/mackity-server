import Foundation
import Network

final class RemoteConnection: Identifiable {
    let id = UUID()
    let endpointDescription: String

    var onStateChange: ((NWConnection.State) -> Void)?
    var onMessage: ((RemoteMessage) -> Void)?
    var onError: ((Error) -> Void)?

    private let connection: NWConnection
    private let queue: DispatchQueue
    private var isReceiving = false

    init(connection: NWConnection, queueLabel: String = "MacRemote.RemoteConnection") {
        self.connection = connection
        self.endpointDescription = connection.endpoint.displayName
        self.queue = DispatchQueue(label: "\(queueLabel).\(UUID().uuidString)")
    }

    init(endpoint: NWEndpoint, queueLabel: String = "MacRemote.RemoteConnection") {
        self.connection = NWConnection(to: endpoint, using: .tcp)
        self.endpointDescription = endpoint.displayName
        self.queue = DispatchQueue(label: "\(queueLabel).\(UUID().uuidString)")
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            self?.onStateChange?(state)

            if case .ready = state {
                self?.receiveNextFrame()
            }

            if case .failed(let error) = state {
                self?.onError?(error)
            }
        }
        connection.start(queue: queue)
    }

    func send(_ message: RemoteMessage) {
        do {
            let frame = try RemoteMessageCodec.encodeFrame(message)
            connection.send(content: frame, completion: .contentProcessed { [weak self] error in
                if let error {
                    self?.onError?(error)
                }
            })
        } catch {
            onError?(error)
        }
    }

    func cancel() {
        connection.cancel()
    }

    private func receiveNextFrame() {
        guard !isReceiving else { return }
        isReceiving = true
        receiveLengthPrefix()
    }

    private func receiveLengthPrefix() {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let error {
                self.isReceiving = false
                self.onError?(error)
                return
            }

            if isComplete {
                self.isReceiving = false
                return
            }

            guard let data, let length = RemoteMessageCodec.frameLength(from: data), length > 0 else {
                self.isReceiving = false
                self.onError?(RemoteMessageCodecError.invalidLengthPrefix)
                return
            }

            self.receivePayload(length: length)
        }
    }

    private func receivePayload(length: Int) {
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            defer {
                if !isComplete {
                    self.receiveLengthPrefix()
                } else {
                    self.isReceiving = false
                }
            }

            if let error {
                self.onError?(error)
                return
            }

            guard let data, data.count == length else {
                self.onError?(RemoteMessageCodecError.invalidLengthPrefix)
                return
            }

            do {
                let message = try RemoteMessageCodec.decode(data)
                self.onMessage?(message)
            } catch {
                self.onError?(error)
            }
        }
    }
}
