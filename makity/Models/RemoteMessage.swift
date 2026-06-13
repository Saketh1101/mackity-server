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

struct MouseMovePayload: Codable, Sendable {
    let deltaX: Double
    let deltaY: Double
}

struct MouseClickPayload: Codable, Sendable {
    let button: MouseButton
    let clickCount: Int
}

struct KeyboardInputPayload: Codable, Sendable {
    let text: String?
    let keyCode: UInt16?
    let modifiers: [String]
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

    init(
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
