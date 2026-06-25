import Foundation

@MainActor
final class RemoteControlService {
    #if os(macOS)
    private let mouseControlService = MouseControlService()
    private let keyboardControlService = KeyboardControlService()
    #endif

    func handle(_ message: RemoteMessage) -> [RemoteMessage] {
        switch message.type {
        case .ping:
            return [.pong]
        case .pong:
            return []
        case .mouseMove, .mouseClick:
            #if os(macOS)
            mouseControlService.handle(message)
            #endif
            return []
        case .keyboardInput:
            #if os(macOS)
            keyboardControlService.handle(message)
            #endif
            return []
        case .screenshotRequest, .screenshotResponse:
            return []
        }
    }

    #if os(macOS)
    func requestAccessibilityPermission() {
        mouseControlService.requestAccessibilityPermission()
        keyboardControlService.requestAccessibilityPermission()
    }

    var accessibilityStatusMessage: String {
        let mouseStatus = mouseControlService.accessibilityStatusMessage
        let keyboardStatus = keyboardControlService.accessibilityStatusMessage

        if mouseStatus == keyboardStatus {
            return mouseStatus
        }

        return "Mouse: \(mouseStatus); Keyboard: \(keyboardStatus)"
    }
    #endif
}
