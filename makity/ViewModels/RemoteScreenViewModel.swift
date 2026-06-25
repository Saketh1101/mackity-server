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

    private let client: MacRemoteClient
    private var cancellables: Set<AnyCancellable> = []

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
        let payload = ScreenshotRequestPayload(maximumWidth: 960, quality: 0.42)
        client.send(RemoteMessage(type: .screenshotRequest, screenshotRequest: payload))
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
        statusMessage = "Receiving screen stream"
    }
}
#endif
