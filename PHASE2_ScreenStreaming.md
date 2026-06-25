# MacRemote Phase 2

Phase 2 adds JPEG screen streaming from the Mac server to the iPhone client.

## What Changed

- The iPhone sends a `screenshotRequest` after connecting.
- The Mac starts a ScreenCaptureKit display stream at 15 FPS.
- Each frame is compressed to JPEG before being sent over the existing TCP connection.
- The iPhone decodes `screenshotResponse` messages and displays the remote screen while preserving aspect ratio.
- The Mac stops screen streaming when the server stops or when all clients disconnect.

## New Files

- `makity/Models/ScreenStreamingConfiguration.swift`
  - Shared stream settings: FPS, max width, JPEG quality.
- `makity/Services/ScreenStreamingService.swift`
  - macOS-only ScreenCaptureKit capture service.
  - Reuses a `CIContext` for JPEG compression.
  - Keeps sample-buffer processing on the ScreenCaptureKit callback queue.
- `makity/ViewModels/RemoteScreenViewModel.swift`
  - iOS-only frame decoder and remote screen state.
- `makity/Views/RemoteScreenView.swift`
  - iOS-only screen display view with connection and frame status.

## Updated Files

- `MacRemoteServer.swift`
  - Starts screen streaming when it receives `screenshotRequest`.
  - Broadcasts `screenshotResponse` frames to connected clients.
- `iPhoneDiscoveryViewModel.swift`
  - Requests the stream automatically after connection.
  - Forwards nested discovery/client updates to SwiftUI.
- `iPhoneDiscoveryView.swift`
  - Adds an `Open Remote Screen` navigation link when connected.
- `MacServerView.swift`
  - Shows Mac screen streaming status.
- `RemoteMessage.swift`
  - Marks the initializer nonisolated for Swift 6 compatibility.

## Permissions

The Mac app needs Screen Recording permission:

1. Run the Mac app.
2. Start the server.
3. Connect from iPhone.
4. If macOS prompts for Screen Recording permission, allow it.
5. If frames do not appear, open System Settings > Privacy & Security > Screen & System Audio Recording and enable MacRemote, then relaunch the Mac app.

## Notes

Phase 2 intentionally uses JPEG frames over the Phase 1 JSON protocol. H.264 hardware encoding, adaptive bitrate, and sub-100ms latency are reserved for Phase 5.

