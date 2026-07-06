import Foundation

#if os(macOS)
import AppKit

/// Posts HID-level media key events using the same mechanism as the keyboard's Fn keys.
/// NX key codes from <IOKit/hidsystem/ev_keymap.h>
@MainActor
final class MediaControlService {
    func press(_ key: MediaKey) {
        let code = nxKeyCode(for: key)
        postNXKey(code)
    }

    private func postNXKey(_ keyCode: Int) {
        let down = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: (keyCode << 16) | (0xa << 8),
            data2: -1
        )
        let up = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: (keyCode << 16) | (0xb << 8),
            data2: -1
        )
        down?.cgEvent?.post(tap: .cghidEventTap)
        up?.cgEvent?.post(tap: .cghidEventTap)
    }

    private func nxKeyCode(for key: MediaKey) -> Int {
        switch key {
        case .volumeUp:        return 0   // NX_KEYTYPE_SOUND_UP
        case .volumeDown:      return 1   // NX_KEYTYPE_SOUND_DOWN
        case .brightnessUp:    return 2   // NX_KEYTYPE_BRIGHTNESS_UP
        case .brightnessDown:  return 3   // NX_KEYTYPE_BRIGHTNESS_DOWN
        case .mute:            return 7   // NX_KEYTYPE_MUTE
        case .playPause:       return 16  // NX_KEYTYPE_PLAY
        case .nextTrack:       return 17  // NX_KEYTYPE_NEXT
        case .previousTrack:   return 18  // NX_KEYTYPE_PREVIOUS
        }
    }
}
#endif
