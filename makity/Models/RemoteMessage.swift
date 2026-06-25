import Foundation

/// Stable service identity used by Bonjour. Keep this value short and version-neutral.
enum MacRemoteService {
    static let bonjourType = "_macremote._tcp"
}

enum RemoteMessageType: String, Codable, CaseIterable, Sendable {
    case ping
    case pong
    case mouseMove
    case mouseClick
    case keyboardInput
    case screenshotRequest
    case screenshotResponse
}

enum MouseButton: String, Codable, Sendable {
    case left
    case right
    case middle
}

enum MouseMoveKind: String, Codable, Sendable {
    case move
    case scroll
}

enum MouseClickAction: String, Codable, Sendable {
    case click
    case down
    case up
}

enum KeyboardSpecialKey: String, Codable, Sendable {
    case enter
    case delete
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
}

enum KeyboardModifier: String, Codable, Sendable {
    case command
    case shift
    case option
    case control
}

struct MouseMovePayload: Codable, Sendable {
    let deltaX: Double
    let deltaY: Double
    let kind: MouseMoveKind

    nonisolated init(deltaX: Double, deltaY: Double, kind: MouseMoveKind = .move) {
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.kind = kind
    }
}

struct MouseClickPayload: Codable, Sendable {
    let button: MouseButton
    let clickCount: Int
    let action: MouseClickAction

    nonisolated init(button: MouseButton, clickCount: Int = 1, action: MouseClickAction = .click) {
        self.button = button
        self.clickCount = clickCount
        self.action = action
    }
}

struct KeyboardInputPayload: Codable, Sendable {
    let text: String?
    let keyCode: UInt16?
    let specialKey: KeyboardSpecialKey?
    let modifiers: [KeyboardModifier]

    nonisolated init(
        text: String? = nil,
        keyCode: UInt16? = nil,
        specialKey: KeyboardSpecialKey? = nil,
        modifiers: [KeyboardModifier] = []
    ) {
        self.text = text
        self.keyCode = keyCode
        self.specialKey = specialKey
        self.modifiers = modifiers
    }
}

struct ScreenshotRequestPayload: Codable, Sendable {
    let maximumWidth: Int?
    let quality: Double?
}

struct ScreenshotResponsePayload: Codable, Sendable {
    let width: Int
    let height: Int
    let jpegBase64: String
}

struct RemoteMessage: Codable, Identifiable, Sendable {
    let id: UUID
    let type: RemoteMessageType
    let createdAt: Date
    let mouseMove: MouseMovePayload?
    let mouseClick: MouseClickPayload?
    let keyboardInput: KeyboardInputPayload?
    let screenshotRequest: ScreenshotRequestPayload?
    let screenshotResponse: ScreenshotResponsePayload?

    nonisolated init(
        id: UUID = UUID(),
        type: RemoteMessageType,
        createdAt: Date = Date(),
        mouseMove: MouseMovePayload? = nil,
        mouseClick: MouseClickPayload? = nil,
        keyboardInput: KeyboardInputPayload? = nil,
        screenshotRequest: ScreenshotRequestPayload? = nil,
        screenshotResponse: ScreenshotResponsePayload? = nil
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.mouseMove = mouseMove
        self.mouseClick = mouseClick
        self.keyboardInput = keyboardInput
        self.screenshotRequest = screenshotRequest
        self.screenshotResponse = screenshotResponse
    }

    static let ping = RemoteMessage(type: .ping)
    static let pong = RemoteMessage(type: .pong)
}
