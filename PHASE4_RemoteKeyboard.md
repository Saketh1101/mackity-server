# MacRemote Phase 4

Phase 4 adds remote keyboard control from iPhone to Mac.

## What Changed

- The iPhone app now shows `Open Keyboard` after connecting to a Mac.
- Typed text is sent to the Mac in real time.
- Delete in the iPhone text field sends Delete key events to the Mac.
- Submit/Return sends Enter.
- Arrow buttons send Up, Down, Left, and Right.
- Command shortcut buttons send common macOS shortcuts.
- The Mac converts `keyboardInput` messages into local keyboard events.

## New Files

- `makity/Services/KeyboardControlService.swift`
  - macOS-only keyboard event injection using `CGEvent`.
  - Supports Unicode text, key codes, special keys, and modifier flags.
- `makity/ViewModels/RemoteKeyboardViewModel.swift`
  - iOS-only keyboard command sender.
- `makity/Views/RemoteKeyboardView.swift`
  - iPhone keyboard control UI.

## Updated Files

- `RemoteMessage.swift`
  - Adds `KeyboardSpecialKey` and typed `KeyboardModifier` values.
  - Extends `KeyboardInputPayload` with `specialKey`.
- `RemoteControlService.swift`
  - Routes keyboard messages to `KeyboardControlService`.
- `iPhoneDiscoveryView.swift`
  - Adds the `Open Keyboard` navigation link.

## Supported Input

- Letters and numbers through the text field.
- Enter.
- Delete.
- Arrow keys.
- Command shortcuts:
  - Cmd C
  - Cmd V
  - Cmd X
  - Cmd A
  - Cmd Z
  - Cmd S

## Required macOS Permission

Keyboard control requires Accessibility permission, the same as mouse control:

1. Run the Mac app.
2. Click `Mouse Permission` in the Mac app. This prompts for the shared Accessibility permission.
3. Open System Settings when macOS prompts.
4. Go to Privacy & Security > Accessibility.
5. Enable MacRemote/makity.
6. Relaunch the Mac app if macOS asks.

