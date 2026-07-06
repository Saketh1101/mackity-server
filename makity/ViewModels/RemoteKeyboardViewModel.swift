import Combine
import Foundation

#if os(iOS)
import UIKit

@MainActor
final class RemoteKeyboardViewModel: ObservableObject {
    @Published var inputText = ""
    @Published private(set) var statusMessage = "Keyboard ready"
    @Published private(set) var receivedClipboard: String?

    private let client: MacRemoteClient
    private var lastText = ""
    private var cancellables: Set<AnyCancellable> = []

    init(client: MacRemoteClient) {
        self.client = client

        client.$lastReceivedMessage
            .compactMap { $0 }
            .filter { $0.type == .clipboardContent }
            .compactMap { $0.clipboardContent?.text }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.receivedClipboard = text
                self?.statusMessage = "Mac clipboard received"
            }
            .store(in: &cancellables)
    }

    // MARK: - Text input

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

    // MARK: - Media keys

    func sendMediaKey(_ key: MediaKey) {
        client.send(RemoteMessage(type: .mediaKey, mediaKey: MediaKeyPayload(key: key)))
        statusMessage = "Sent \(mediaKeyLabel(for: key))"
    }

    // MARK: - Clipboard

    func pushClipboard() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            statusMessage = "iPhone clipboard is empty"
            return
        }
        client.send(RemoteMessage(type: .clipboardPush, clipboardContent: ClipboardPayload(text: text)))
        statusMessage = "Clipboard sent to Mac"
    }

    func pullClipboard() {
        client.send(RemoteMessage(type: .clipboardPull))
        statusMessage = "Requesting Mac clipboard..."
    }

    func copyReceivedClipboard() {
        guard let text = receivedClipboard else { return }
        UIPasteboard.general.string = text
        statusMessage = "Copied to iPhone"
    }

    func clearReceivedClipboard() {
        receivedClipboard = nil
    }

    // MARK: - Private

    private func label(for key: KeyboardSpecialKey) -> String {
        switch key {
        case .enter:      return "Enter"
        case .delete:     return "Delete"
        case .tab:        return "Tab"
        case .escape:     return "Escape"
        case .arrowUp:    return "Up"
        case .arrowDown:  return "Down"
        case .arrowLeft:  return "Left"
        case .arrowRight: return "Right"
        }
    }

    private func mediaKeyLabel(for key: MediaKey) -> String {
        switch key {
        case .volumeUp:        return "Volume Up"
        case .volumeDown:      return "Volume Down"
        case .mute:            return "Mute"
        case .playPause:       return "Play/Pause"
        case .nextTrack:       return "Next"
        case .previousTrack:   return "Previous"
        case .brightnessUp:    return "Brightness Up"
        case .brightnessDown:  return "Brightness Down"
        }
    }
}
#endif
