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
    case mouseAbsoluteMove
    case keyboardInput
    case mediaKey
    case clipboardPush      // iPhone → Mac: write text to Mac clipboard
    case clipboardPull      // iPhone → Mac: request Mac clipboard content
    case clipboardContent   // Mac → iPhone: clipboard text response
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
    case tab
    case escape
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

enum MediaKey: String, Codable, Sendable {
    case volumeUp
    case volumeDown
    case mute
    case playPause
    case nextTrack
    case previousTrack
    case brightnessUp
    case brightnessDown
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

/// Normalized (0–1) absolute screen position. The Mac converts to display coordinates.
struct MouseAbsoluteMovePayload: Codable, Sendable {
    let normalizedX: Double
    let normalizedY: Double
    let click: Bool
    let button: MouseButton

    nonisolated init(normalizedX: Double, normalizedY: Double, click: Bool = false, button: MouseButton = .left) {
        self.normalizedX = max(0, min(1, normalizedX))
        self.normalizedY = max(0, min(1, normalizedY))
        self.click = click
        self.button = button
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

struct MediaKeyPayload: Codable, Sendable {
    let key: MediaKey

    nonisolated init(key: MediaKey) {
        self.key = key
    }
}

struct ClipboardPayload: Codable, Sendable {
    let text: String

    nonisolated init(text: String) {
        self.text = text
    }
}

struct ScreenshotRequestPayload: Codable, Sendable {
    let maximumWidth: Int?
    let quality: Double?
    let framesPerSecond: Int?
    let displayIndex: Int?

    nonisolated init(maximumWidth: Int? = nil, quality: Double? = nil, framesPerSecond: Int? = nil, displayIndex: Int? = nil) {
        self.maximumWidth = maximumWidth
        self.quality = quality
        self.framesPerSecond = framesPerSecond
        self.displayIndex = displayIndex
    }
}

struct ScreenshotResponsePayload: Codable, Sendable {
    let width: Int
    let height: Int
    let jpegBase64: String
    let encodedByteCount: Int
    let sequenceNumber: Int
    let displayCount: Int

    nonisolated init(
        width: Int,
        height: Int,
        jpegBase64: String,
        encodedByteCount: Int,
        sequenceNumber: Int,
        displayCount: Int = 1
    ) {
        self.width = width
        self.height = height
        self.jpegBase64 = jpegBase64
        self.encodedByteCount = encodedByteCount
        self.sequenceNumber = sequenceNumber
        self.displayCount = displayCount
    }
}

struct RemoteMessage: Codable, Identifiable, Sendable {
    let id: UUID
    let type: RemoteMessageType
    let createdAt: Date
    let mouseMove: MouseMovePayload?
    let mouseClick: MouseClickPayload?
    let mouseAbsoluteMove: MouseAbsoluteMovePayload?
    let keyboardInput: KeyboardInputPayload?
    let mediaKey: MediaKeyPayload?
    let clipboardContent: ClipboardPayload?
    let screenshotRequest: ScreenshotRequestPayload?
    let screenshotResponse: ScreenshotResponsePayload?

    nonisolated init(
        id: UUID = UUID(),
        type: RemoteMessageType,
        createdAt: Date = Date(),
        mouseMove: MouseMovePayload? = nil,
        mouseClick: MouseClickPayload? = nil,
        mouseAbsoluteMove: MouseAbsoluteMovePayload? = nil,
        keyboardInput: KeyboardInputPayload? = nil,
        mediaKey: MediaKeyPayload? = nil,
        clipboardContent: ClipboardPayload? = nil,
        screenshotRequest: ScreenshotRequestPayload? = nil,
        screenshotResponse: ScreenshotResponsePayload? = nil
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.mouseMove = mouseMove
        self.mouseClick = mouseClick
        self.mouseAbsoluteMove = mouseAbsoluteMove
        self.keyboardInput = keyboardInput
        self.mediaKey = mediaKey
        self.clipboardContent = clipboardContent
        self.screenshotRequest = screenshotRequest
        self.screenshotResponse = screenshotResponse
    }

    static let ping = RemoteMessage(type: .ping)
    static let pong = RemoteMessage(type: .pong)
}
