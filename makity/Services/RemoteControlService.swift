import Foundation

@MainActor
final class RemoteControlService {
    func handle(_ message: RemoteMessage) -> [RemoteMessage] {
        switch message.type {
        case .ping:
            return [.pong]
        case .pong:
            return []
        case .mouseMove, .mouseClick, .keyboardInput, .screenshotRequest, .screenshotResponse:
            // Phase 1 defines and transports these messages. Platform actions are implemented in later phases.
            return []
        }
    }
}
