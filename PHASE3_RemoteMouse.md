# MacRemote Phase 3

Phase 3 adds remote mouse control from iPhone to Mac.

## What Changed

- The iPhone app now shows `Open Touchpad` after connecting to a Mac.
- The touchpad sends mouse movement, clicks, double-clicks, scrolls, and drag actions over the existing TCP connection.
- The Mac receives `mouseMove` and `mouseClick` messages and converts them into local cursor events.
- The Mac screen shows Accessibility permission status and includes a `Mouse Permission` button.

## New Files

- `makity/Services/MouseControlService.swift`
  - macOS-only cursor, click, drag, and scroll event injection.
  - Uses Accessibility trust checks and `CGEvent`.
- `makity/ViewModels/RemoteMouseViewModel.swift`
  - iOS-only mouse command sender.
- `makity/Views/TouchpadSurface.swift`
  - UIKit gesture bridge for reliable one-finger move, tap, double tap, two-finger scroll, and drag mode.
- `makity/Views/RemoteMouseView.swift`
  - Full-screen iPhone touchpad UI.

## Updated Files

- `RemoteMessage.swift`
  - Extends mouse payloads with move-vs-scroll and click/down/up actions.
- `RemoteControlService.swift`
  - Routes mouse messages to `MouseControlService`.
- `MacRemoteServer.swift`
  - Exposes Accessibility permission status and prompt action.
- `MacServerView.swift`
  - Adds mouse permission status and button.
- `iPhoneDiscoveryView.swift`
  - Adds the `Open Touchpad` navigation link.

## Gestures

- Single tap: left click.
- Double tap: double click.
- One-finger pan: move cursor.
- Two-finger pan: scroll.
- Drag mode toggle + one-finger pan: mouse down, move, mouse up.

## Required macOS Permission

Mouse control requires Accessibility permission:

1. Run the Mac app.
2. Click `Mouse Permission`.
3. Open System Settings when macOS prompts.
4. Go to Privacy & Security > Accessibility.
5. Enable MacRemote/makity.
6. Relaunch the Mac app if macOS asks.

