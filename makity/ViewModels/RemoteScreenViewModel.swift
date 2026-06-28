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
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        client.$lastReceivedMessage
            .compactMap { $0?.screenshotResponse }
            .sink { [weak self] payload in
                self?.handle(payload)
            }
            .store(in: &cancellables)
    }

    func requestStream() {
        sendStreamRequest()
        statusMessage = "Requesting screen stream..."
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
        updateFrameRate()
        adjustStreamProfileIfNeeded()
        statusMessage = "Receiving screen stream"
    }

    private func sendStreamRequest() {
        let payload = ScreenshotRequestPayload(
            maximumWidth: maximumWidth,
            quality: quality,
            framesPerSecond: framesPerSecond
        )
        client.send(RemoteMessage(type: .screenshotRequest, screenshotRequest: payload))
        streamProfile = "\(maximumWidth)px / \(framesPerSecond) FPS"
    }

    private func updateFrameRate() {
        let now = Date()
        recentFrameDates.append(now)
        recentFrameDates.removeAll { now.timeIntervalSince($0) > 3 }

        guard let firstFrameDate = recentFrameDates.first, recentFrameDates.count > 1 else {
            averageFrameRate = 0
            return
        }

        let elapsed = now.timeIntervalSince(firstFrameDate)
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
