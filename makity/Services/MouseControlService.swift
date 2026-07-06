import Combine
import Foundation

#if os(macOS)
import ApplicationServices
import CoreGraphics

@MainActor
final class MouseControlService: ObservableObject {
    @Published private(set) var accessibilityStatusMessage = "Accessibility permission not checked"

    private let movementScale: Double = 1.4

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        accessibilityStatusMessage = trusted
            ? "Accessibility permission granted"
            : "Enable Accessibility permission for MacRemote"
    }

    func handle(_ message: RemoteMessage) {
        guard isAccessibilityTrusted else {
            accessibilityStatusMessage = "Enable Accessibility permission for mouse control"
            requestAccessibilityPermission()
            return
        }

        switch message.type {
        case .mouseMove:
            guard let payload = message.mouseMove else { return }
            switch payload.kind {
            case .move:
                moveCursor(deltaX: payload.deltaX, deltaY: payload.deltaY)
            case .scroll:
                scroll(deltaX: payload.deltaX, deltaY: payload.deltaY)
            }
        case .mouseClick:
            guard let payload = message.mouseClick else { return }
            handleClick(payload)
        case .mouseAbsoluteMove:
            guard let payload = message.mouseAbsoluteMove else { return }
            moveToAbsolutePosition(
                normalizedX: payload.normalizedX,
                normalizedY: payload.normalizedY,
                click: payload.click,
                button: payload.button
            )
        default:
            break
        }
    }

    private func moveCursor(deltaX: Double, deltaY: Double) {
        guard let currentEvent = CGEvent(source: nil) else { return }
        let currentLocation = currentEvent.location
        let nextLocation = CGPoint(
            x: currentLocation.x + deltaX * movementScale,
            y: currentLocation.y + deltaY * movementScale
        )

        CGWarpMouseCursorPosition(nextLocation)
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))

        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: nextLocation,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    private func moveToAbsolutePosition(normalizedX: Double, normalizedY: Double, click: Bool, button: MouseButton) {
        let bounds = CGDisplayBounds(CGMainDisplayID())
        let position = CGPoint(
            x: bounds.origin.x + normalizedX * bounds.size.width,
            y: bounds.origin.y + normalizedY * bounds.size.height
        )

        CGWarpMouseCursorPosition(position)
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))

        CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: position, mouseButton: .left)?
            .post(tap: .cghidEventTap)

        guard click else { return }

        let cgButton = cgMouseButton(for: button)
        let downType = mouseEventType(for: button, isDown: true)
        let upType = mouseEventType(for: button, isDown: false)

        guard let down = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: position, mouseButton: cgButton),
              let up = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: position, mouseButton: cgButton)
        else { return }

        down.setIntegerValueField(.mouseEventClickState, value: 1)
        up.setIntegerValueField(.mouseEventClickState, value: 1)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private func scroll(deltaX: Double, deltaY: Double) {
        let vertical = Int32((-deltaY).rounded())
        let horizontal = Int32((-deltaX).rounded())

        CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: vertical,
            wheel2: horizontal,
            wheel3: 0
        )?.post(tap: .cghidEventTap)
    }

    private func handleClick(_ payload: MouseClickPayload) {
        switch payload.action {
        case .click:
            click(button: payload.button, clickCount: payload.clickCount)
        case .down:
            postMouseButton(payload.button, isDown: true, clickCount: 1)
        case .up:
            postMouseButton(payload.button, isDown: false, clickCount: 1)
        }
    }

    private func click(button: MouseButton, clickCount: Int) {
        let count = max(1, clickCount)
        for _ in 0..<count {
            postMouseButton(button, isDown: true, clickCount: count)
            postMouseButton(button, isDown: false, clickCount: count)
        }
    }

    private func postMouseButton(_ button: MouseButton, isDown: Bool, clickCount: Int) {
        guard let currentEvent = CGEvent(source: nil) else { return }
        let location = currentEvent.location
        let cgButton = cgMouseButton(for: button)
        let eventType = mouseEventType(for: button, isDown: isDown)

        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: eventType,
            mouseCursorPosition: location,
            mouseButton: cgButton
        ) else {
            return
        }

        event.setIntegerValueField(.mouseEventClickState, value: Int64(max(1, clickCount)))
        event.post(tap: .cghidEventTap)
    }

    private func cgMouseButton(for button: MouseButton) -> CGMouseButton {
        switch button {
        case .left:
            return .left
        case .right:
            return .right
        case .middle:
            return .center
        }
    }

    private func mouseEventType(for button: MouseButton, isDown: Bool) -> CGEventType {
        switch (button, isDown) {
        case (.left, true):
            return .leftMouseDown
        case (.left, false):
            return .leftMouseUp
        case (.right, true):
            return .rightMouseDown
        case (.right, false):
            return .rightMouseUp
        case (.middle, true):
            return .otherMouseDown
        case (.middle, false):
            return .otherMouseUp
        }
    }
}
#endif
