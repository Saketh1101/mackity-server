import Combine
import Foundation

#if os(iOS)
@MainActor
final class RemoteMouseViewModel: ObservableObject {
    @Published var isDragModeEnabled = false
    @Published private(set) var statusMessage = "Touchpad ready"

    private let client: MacRemoteClient

    init(client: MacRemoteClient) {
        self.client = client
    }

    func move(deltaX: Double, deltaY: Double) {
        let payload = MouseMovePayload(deltaX: deltaX, deltaY: deltaY, kind: .move)
        client.send(RemoteMessage(type: .mouseMove, mouseMove: payload))
        statusMessage = "Moving pointer"
    }

    func scroll(deltaX: Double, deltaY: Double) {
        let payload = MouseMovePayload(deltaX: deltaX, deltaY: deltaY, kind: .scroll)
        client.send(RemoteMessage(type: .mouseMove, mouseMove: payload))
        statusMessage = "Scrolling"
    }

    func click(clickCount: Int = 1) {
        let payload = MouseClickPayload(button: .left, clickCount: clickCount, action: .click)
        client.send(RemoteMessage(type: .mouseClick, mouseClick: payload))
        statusMessage = clickCount == 2 ? "Double click" : "Click"
    }

    func rightClick() {
        let payload = MouseClickPayload(button: .right, clickCount: 1, action: .click)
        client.send(RemoteMessage(type: .mouseClick, mouseClick: payload))
        statusMessage = "Right click"
    }

    func beginDrag() {
        guard isDragModeEnabled else { return }
        let payload = MouseClickPayload(button: .left, clickCount: 1, action: .down)
        client.send(RemoteMessage(type: .mouseClick, mouseClick: payload))
        statusMessage = "Drag started"
    }

    func endDrag() {
        guard isDragModeEnabled else { return }
        let payload = MouseClickPayload(button: .left, clickCount: 1, action: .up)
        client.send(RemoteMessage(type: .mouseClick, mouseClick: payload))
        statusMessage = "Drag ended"
    }
}
#endif
