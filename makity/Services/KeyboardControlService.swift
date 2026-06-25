import Combine
import Foundation

#if os(macOS)
import ApplicationServices
import CoreGraphics

@MainActor
final class KeyboardControlService: ObservableObject {
    @Published private(set) var accessibilityStatusMessage = "Accessibility permission not checked"

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        accessibilityStatusMessage = trusted
            ? "Accessibility permission granted"
            : "Enable Accessibility permission for keyboard control"
    }

    func handle(_ message: RemoteMessage) {
        guard message.type == .keyboardInput, let payload = message.keyboardInput else { return }
        guard isAccessibilityTrusted else {
            accessibilityStatusMessage = "Enable Accessibility permission for keyboard control"
            requestAccessibilityPermission()
            return
        }

        if let text = payload.text, !text.isEmpty {
            sendText(text)
            accessibilityStatusMessage = "Keyboard input sent"
            return
        }

        if let specialKey = payload.specialKey, let keyCode = keyCode(for: specialKey) {
            sendKeyCode(keyCode, modifiers: payload.modifiers)
            accessibilityStatusMessage = "Keyboard input sent"
            return
        }

        if let keyCode = payload.keyCode {
            sendKeyCode(CGKeyCode(keyCode), modifiers: payload.modifiers)
            accessibilityStatusMessage = "Keyboard shortcut sent"
        }
    }

    private func sendText(_ text: String) {
        for scalar in text.unicodeScalars {
            var value = UniChar(scalar.value)
            guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
                continue
            }

            keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }

    private func sendKeyCode(_ keyCode: CGKeyCode, modifiers: [KeyboardModifier]) {
        let flags = eventFlags(for: modifiers)
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func eventFlags(for modifiers: [KeyboardModifier]) -> CGEventFlags {
        modifiers.reduce(into: CGEventFlags()) { flags, modifier in
            switch modifier {
            case .command:
                flags.insert(.maskCommand)
            case .shift:
                flags.insert(.maskShift)
            case .option:
                flags.insert(.maskAlternate)
            case .control:
                flags.insert(.maskControl)
            }
        }
    }

    private func keyCode(for specialKey: KeyboardSpecialKey) -> CGKeyCode? {
        switch specialKey {
        case .enter:
            return 36
        case .delete:
            return 51
        case .arrowLeft:
            return 123
        case .arrowRight:
            return 124
        case .arrowDown:
            return 125
        case .arrowUp:
            return 126
        }
    }
}
#endif
