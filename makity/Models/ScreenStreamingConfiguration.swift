import Foundation

struct ScreenStreamingConfiguration: Equatable, Sendable {
    let framesPerSecond: Int
    let maximumWidth: Int
    let jpegQuality: Double
    let displayIndex: Int

    nonisolated init(
        framesPerSecond: Int = 15,
        maximumWidth: Int = 1280,
        jpegQuality: Double = 0.55,
        displayIndex: Int = 0
    ) {
        self.framesPerSecond = max(1, min(framesPerSecond, 30))
        self.maximumWidth = max(320, min(maximumWidth, 1920))
        self.jpegQuality = max(0.1, min(jpegQuality, 0.95))
        self.displayIndex = max(0, displayIndex)
    }

    nonisolated init(request: ScreenshotRequestPayload?) {
        self.init(
            framesPerSecond: request?.framesPerSecond ?? 15,
            maximumWidth: request?.maximumWidth ?? 1280,
            jpegQuality: request?.quality ?? 0.55,
            displayIndex: request?.displayIndex ?? 0
        )
    }
}
