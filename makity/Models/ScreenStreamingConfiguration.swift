import Foundation

struct ScreenStreamingConfiguration: Sendable {
    let framesPerSecond: Int
    let maximumWidth: Int
    let jpegQuality: Double

    nonisolated init(framesPerSecond: Int = 15, maximumWidth: Int = 1280, jpegQuality: Double = 0.55) {
        self.framesPerSecond = max(1, min(framesPerSecond, 30))
        self.maximumWidth = max(320, maximumWidth)
        self.jpegQuality = max(0.1, min(jpegQuality, 0.95))
    }

    nonisolated init(request: ScreenshotRequestPayload?) {
        self.init(
            framesPerSecond: 15,
            maximumWidth: request?.maximumWidth ?? 1280,
            jpegQuality: request?.quality ?? 0.55
        )
    }
}
