import Combine
import Foundation

#if os(iOS)
import UIKit

@MainActor
final class RemoteScreenViewModel: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var frameSize = CGSize.zero
    @Published private(set) var frameCount = 0
    @Published private(set) var statusMessage = "Waiting for screen frames"
    @Published private(set) var averageFrameRate = 0.0
    @Published private(set) var lastFrameKilobytes = 0.0
    @Published private(set) var streamProfile = "960px / 15 FPS"
    @Published private(set) var macDisplayCount = 1
    @Published var selectedDisplayIndex = 0

    private let client: MacRemoteClient
    private var cancellables: Set<AnyCancellable> = []
    private var recentFrameDates: [Date] = []
    private var lastProfileAdjustmentDate = Date.distantPast
    private var maximumWidth = 960
    private var quality = 0.42
    private var framesPerSecond = 15

    init(client: MacRemoteClient) {
        self.client = client

        client.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        client.$lastReceivedMessage
            .compactMap { $0?.screenshotResponse }
            .sink { [weak self] payload in self?.handle(payload) }
            .store(in: &cancellables)
    }

    func requestStream() {
        sendStreamRequest()
        statusMessage = "Requesting screen stream..."
    }

    func switchDisplay(to index: Int) {
        selectedDisplayIndex = index
        sendStreamRequest()
    }

    // MARK: - Screen interaction (absolute positioning)

    func absoluteClick(at viewPoint: CGPoint, in viewSize: CGSize, button: MouseButton = .left) {
        guard let normalized = normalizedPosition(viewPoint: viewPoint, viewSize: viewSize) else { return }
        let payload = MouseAbsoluteMovePayload(
            normalizedX: normalized.x,
            normalizedY: normalized.y,
            click: true,
            button: button
        )
        client.send(RemoteMessage(type: .mouseAbsoluteMove, mouseAbsoluteMove: payload))
        statusMessage = button == .right ? "Right click" : "Click"
    }

    func absoluteMove(at viewPoint: CGPoint, in viewSize: CGSize) {
        guard let normalized = normalizedPosition(viewPoint: viewPoint, viewSize: viewSize) else { return }
        let payload = MouseAbsoluteMovePayload(normalizedX: normalized.x, normalizedY: normalized.y, click: false)
        client.send(RemoteMessage(type: .mouseAbsoluteMove, mouseAbsoluteMove: payload))
    }

    func screenScroll(deltaX: Double, deltaY: Double) {
        let payload = MouseMovePayload(deltaX: deltaX, deltaY: deltaY, kind: .scroll)
        client.send(RemoteMessage(type: .mouseMove, mouseMove: payload))
    }

    /// Returns the CGRect within viewSize where the screen image is rendered (accounting for letterboxing/pillarboxing).
    func renderedImageFrame(in viewSize: CGSize) -> CGRect {
        guard frameSize.width > 0, frameSize.height > 0, viewSize.width > 0, viewSize.height > 0 else {
            return CGRect(origin: .zero, size: viewSize)
        }
        let viewAspect = viewSize.width / viewSize.height
        let imageAspect = frameSize.width / frameSize.height

        if imageAspect > viewAspect {
            let h = viewSize.width / imageAspect
            return CGRect(x: 0, y: (viewSize.height - h) / 2, width: viewSize.width, height: h)
        } else {
            let w = viewSize.height * imageAspect
            return CGRect(x: (viewSize.width - w) / 2, y: 0, width: w, height: viewSize.height)
        }
    }

    // MARK: - Private

    private func normalizedPosition(viewPoint: CGPoint, viewSize: CGSize) -> CGPoint? {
        let frame = renderedImageFrame(in: viewSize)
        guard frame.width > 0, frame.height > 0 else { return nil }
        let nx = (viewPoint.x - frame.minX) / frame.width
        let ny = (viewPoint.y - frame.minY) / frame.height
        guard nx >= 0, nx <= 1, ny >= 0, ny <= 1 else { return nil }
        return CGPoint(x: nx, y: ny)
    }

    private func handle(_ payload: ScreenshotResponsePayload) {
        guard let data = Data(base64Encoded: payload.jpegBase64), let uiImage = UIImage(data: data) else {
            statusMessage = "Failed to decode screen frame"
            return
        }

        image = uiImage
        frameSize = CGSize(width: payload.width, height: payload.height)
        frameCount += 1
        lastFrameKilobytes = Double(payload.encodedByteCount) / 1024.0
        macDisplayCount = payload.displayCount
        updateFrameRate()
        adjustStreamProfileIfNeeded()
        statusMessage = "Receiving screen stream"
    }

    private func sendStreamRequest() {
        let payload = ScreenshotRequestPayload(
            maximumWidth: maximumWidth,
            quality: quality,
            framesPerSecond: framesPerSecond,
            displayIndex: selectedDisplayIndex
        )
        client.send(RemoteMessage(type: .screenshotRequest, screenshotRequest: payload))
        streamProfile = "\(maximumWidth)px / \(framesPerSecond) FPS"
    }

    private func updateFrameRate() {
        let now = Date()
        recentFrameDates.append(now)
        recentFrameDates.removeAll { now.timeIntervalSince($0) > 3 }

        guard let first = recentFrameDates.first, recentFrameDates.count > 1 else {
            averageFrameRate = 0
            return
        }
        let elapsed = now.timeIntervalSince(first)
        averageFrameRate = elapsed > 0 ? Double(recentFrameDates.count - 1) / elapsed : 0
    }

    private func adjustStreamProfileIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastProfileAdjustmentDate) > 5 else { return }
        guard frameCount > framesPerSecond else { return }

        if averageFrameRate < Double(framesPerSecond) * 0.6, maximumWidth > 640 {
            maximumWidth = 640
            quality = 0.32
            framesPerSecond = 12
            lastProfileAdjustmentDate = now
            sendStreamRequest()
            statusMessage = "Reducing stream quality"
        } else if averageFrameRate > Double(framesPerSecond) * 0.9, maximumWidth < 1280 {
            maximumWidth = 1280
            quality = 0.5
            framesPerSecond = 15
            lastProfileAdjustmentDate = now
            sendStreamRequest()
            statusMessage = "Increasing stream quality"
        }
    }
}
#endif
