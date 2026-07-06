import Combine
import Foundation

#if os(macOS)
import CoreImage
import CoreMedia
import ImageIO
import QuartzCore
import ScreenCaptureKit

@MainActor
final class ScreenStreamingService: NSObject, ObservableObject {
    @Published private(set) var isStreaming = false
    @Published private(set) var statusMessage = "Screen stream stopped"
    @Published private(set) var availableDisplayCount = 1

    var onFrame: ((RemoteMessage) -> Void)?

    private var stream: SCStream?
    private let captureQueue = DispatchQueue(label: "MacRemote.ScreenStreaming.Capture", qos: .userInteractive)
    private let ciContext = CIContext(options: [.cacheIntermediates: false])
    private let jpegColorSpace = CGColorSpaceCreateDeviceRGB()
    nonisolated(unsafe) private var configuration = ScreenStreamingConfiguration()
    nonisolated(unsafe) private var lastFrameTime: CFTimeInterval = 0
    nonisolated(unsafe) private var isEncodingFrame = false
    nonisolated(unsafe) private var frameSequenceNumber = 0
    nonisolated(unsafe) private var capturedDisplayCount = 1

    func start(configuration: ScreenStreamingConfiguration = ScreenStreamingConfiguration()) async {
        if isStreaming {
            guard self.configuration != configuration else { return }
            await stop()
        }

        self.configuration = configuration
        lastFrameTime = 0
        frameSequenceNumber = 0

        do {
            let shareableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            let displays = shareableContent.displays
            capturedDisplayCount = displays.count
            availableDisplayCount = displays.count

            let displayIndex = min(configuration.displayIndex, max(0, displays.count - 1))
            guard let display = displays[safe: displayIndex] ?? displays.first else {
                statusMessage = "No display available to capture"
                return
            }

            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let streamConfiguration = makeStreamConfiguration(for: display, configuration: configuration)
            let stream = SCStream(filter: filter, configuration: streamConfiguration, delegate: self)

            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
            try await stream.startCapture()

            self.stream = stream
            isStreaming = true
            let displayLabel = displays.count > 1 ? " (Display \(displayIndex + 1)/\(displays.count))" : ""
            statusMessage = "Streaming at \(configuration.framesPerSecond) FPS\(displayLabel)"
        } catch {
            isStreaming = false
            statusMessage = "Screen streaming failed: \(error.localizedDescription)"
            stream = nil
        }
    }

    func stop() async {
        guard let stream else {
            isStreaming = false
            statusMessage = "Screen stream stopped"
            return
        }

        do {
            try await stream.stopCapture()
        } catch {
            statusMessage = "Screen stream stopped with error: \(error.localizedDescription)"
        }

        self.stream = nil
        isStreaming = false
        isEncodingFrame = false
        frameSequenceNumber = 0
        statusMessage = "Screen stream stopped"
    }

    private func makeStreamConfiguration(
        for display: SCDisplay,
        configuration: ScreenStreamingConfiguration
    ) -> SCStreamConfiguration {
        let streamConfiguration = SCStreamConfiguration()
        let scale = min(1.0, Double(configuration.maximumWidth) / Double(max(display.width, 1)))

        streamConfiguration.width = max(1, Int(Double(display.width) * scale))
        streamConfiguration.height = max(1, Int(Double(display.height) * scale))
        streamConfiguration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(configuration.framesPerSecond))
        streamConfiguration.queueDepth = 3
        streamConfiguration.pixelFormat = kCVPixelFormatType_32BGRA
        streamConfiguration.showsCursor = true
        return streamConfiguration
    }

    private nonisolated func makeFrameMessage(from sampleBuffer: CMSampleBuffer) -> RemoteMessage? {
        guard sampleBuffer.isValid else { return nil }
        guard shouldEmitFrame() else { return nil }
        guard let imageBuffer = sampleBuffer.imageBuffer else {
            isEncodingFrame = false
            return nil
        }
        guard isCompleteFrame(sampleBuffer) else {
            isEncodingFrame = false
            return nil
        }

        return autoreleasepool {
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let extent = ciImage.extent.integral
            let compressionKey = CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String)

            guard let jpegData = ciContext.jpegRepresentation(
                of: ciImage,
                colorSpace: jpegColorSpace,
                options: [compressionKey: configuration.jpegQuality]
            ) else {
                isEncodingFrame = false
                return nil
            }

            frameSequenceNumber += 1
            let payload = ScreenshotResponsePayload(
                width: Int(extent.width),
                height: Int(extent.height),
                jpegBase64: jpegData.base64EncodedString(),
                encodedByteCount: jpegData.count,
                sequenceNumber: frameSequenceNumber,
                displayCount: capturedDisplayCount
            )
            return RemoteMessage(type: .screenshotResponse, screenshotResponse: payload)
        }
    }

    private nonisolated func shouldEmitFrame() -> Bool {
        guard !isEncodingFrame else { return false }

        let now = CACurrentMediaTime()
        let minimumInterval = 1.0 / Double(max(configuration.framesPerSecond, 1))
        guard now - lastFrameTime >= minimumInterval else { return false }

        lastFrameTime = now
        isEncodingFrame = true
        return true
    }

    private nonisolated func isCompleteFrame(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer,
            createIfNecessary: false
        ) as? [[SCStreamFrameInfo: Any]],
            let attachments = attachmentsArray.first,
            let statusRawValue = attachments[.status] as? Int,
            let status = SCFrameStatus(rawValue: statusRawValue)
        else {
            return false
        }

        return status == .complete
    }
}

extension ScreenStreamingService: SCStreamOutput, SCStreamDelegate {
    nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen else { return }
        guard let message = makeFrameMessage(from: sampleBuffer) else { return }

        Task { @MainActor in
            self.onFrame?(message)
            self.isEncodingFrame = false
        }
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            self.isStreaming = false
            self.statusMessage = "Screen stream stopped: \(error.localizedDescription)"
            self.stream = nil
            self.isEncodingFrame = false
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
#endif
