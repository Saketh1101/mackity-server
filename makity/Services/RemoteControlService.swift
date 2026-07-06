import Foundation

@MainActor
final class RemoteControlService {
    #if os(macOS)
    private let mouseControlService = MouseControlService()
    private let keyboardControlService = KeyboardControlService()
    private let mediaControlService = MediaControlService()
    #endif

    func handle(_ message: RemoteMessage) -> [RemoteMessage] {
        switch message.type {
        case .ping:
            return [.pong]
        case .pong:
            return []

        case .mouseMove, .mouseClick, .mouseAbsoluteMove:
            #if os(macOS)
            mouseControlService.handle(message)
            #endif
            return []

        case .keyboardInput:
            #if os(macOS)
            keyboardControlService.handle(message)
            #endif
            return []

        case .mediaKey:
            #if os(macOS)
            if let payload = message.mediaKey {
                mediaControlService.press(payload.key)
            }
            #endif
            return []

        case .clipboardPush:
            #if os(macOS)
            if let payload = message.clipboardContent {
                ClipboardService.write(payload.text)
            }
            #endif
            return []

        case .clipboardPull:
            #if os(macOS)
            if let text = ClipboardService.read() {
                return [RemoteMessage(type: .clipboardContent, clipboardContent: ClipboardPayload(text: text))]
            }
            #endif
            return []

        case .clipboardContent:
            return []   // handled client-side

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
