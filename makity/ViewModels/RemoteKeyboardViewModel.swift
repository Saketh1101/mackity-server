import Combine
import Foundation

#if os(iOS)
@MainActor
final class RemoteKeyboardViewModel: ObservableObject {
    @Published var inputText = ""
    @Published private(set) var statusMessage = "Keyboard ready"

    private let client: MacRemoteClient
    private var lastText = ""

    init(client: MacRemoteClient) {
        self.client = client
    }

    func handleTextChange(_ newValue: String) {
        defer { lastText = newValue }

        if newValue.count > lastText.count, newValue.hasPrefix(lastText) {
            let inserted = String(newValue.dropFirst(lastText.count))
            sendText(inserted)
            return
        }

        if newValue.count < lastText.count {
            let deleteCount = lastText.count - newValue.count
            for _ in 0..<deleteCount {
                sendSpecialKey(.delete)
            }
            return
        }

        if newValue != lastText {
            sendText(newValue)
        }
    }

    func sendText(_ text: String) {
        guard !text.isEmpty else { return }
        let payload = KeyboardInputPayload(text: text)
        client.send(RemoteMessage(type: .keyboardInput, keyboardInput: payload))
        statusMessage = "Sent text"
    }

    func sendSpecialKey(_ key: KeyboardSpecialKey) {
        let payload = KeyboardInputPayload(specialKey: key)
        client.send(RemoteMessage(type: .keyboardInput, keyboardInput: payload))
        statusMessage = "Sent \(label(for: key))"
    }

    func sendShortcut(keyCode: UInt16, label: String, modifiers: [KeyboardModifier] = [.command]) {
        let payload = KeyboardInputPayload(keyCode: keyCode, modifiers: modifiers)
        client.send(RemoteMessage(type: .keyboardInput, keyboardInput: payload))
        statusMessage = "Sent \(label)"
    }

    func clearInput() {
        inputText = ""
        lastText = ""
    }

    private func label(for key: KeyboardSpecialKey) -> String {
        switch key {
        case .enter:
            return "Enter"
        case .delete:
            return "Delete"
        case .arrowUp:
            return "Up"
        case .arrowDown:
            return "Down"
        case .arrowLeft:
            return "Left"
        case .arrowRight:
            return "Right"
        }
    }
}
#endif
