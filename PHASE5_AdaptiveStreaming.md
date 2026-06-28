# MacRemote Phase 5

Phase 5 improves remote screen streaming stability with client-requested stream profiles and live frame telemetry.

## What Changed

- The iPhone now requests screen streams with maximum width, JPEG quality, and target FPS.
- The Mac restarts ScreenCaptureKit streaming when a connected client requests a different stream profile.
- Each screen frame includes encoded byte size and a sequence number.
- The iPhone displays received frame count, estimated FPS, frame size in KB, and the active stream profile.
- The iPhone automatically reduces stream quality if delivered FPS falls too far behind the requested target.
- The stream can recover back to a higher profile when frame delivery is healthy.

## Updated Files

- `makity/Models/RemoteMessage.swift`
  - Adds `framesPerSecond` to `ScreenshotRequestPayload`.
  - Adds `encodedByteCount` and `sequenceNumber` to `ScreenshotResponsePayload`.
- `makity/Models/ScreenStreamingConfiguration.swift`
  - Makes stream settings equatable and clamps max width to a bounded range.
  - Reads requested FPS from screenshot requests.
- `makity/Services/ScreenStreamingService.swift`
  - Restarts active capture when the requested stream profile changes.
  - Tracks frame sequence numbers.
- `makity/ViewModels/RemoteScreenViewModel.swift`
  - Tracks FPS and frame byte size.
  - Sends adaptive stream profile requests.
- `makity/Views/RemoteScreenView.swift`
  - Shows live stream telemetry in the remote screen status bar.

## Notes

This phase keeps the existing JPEG-over-TCP transport to reduce risk while improving practical responsiveness. A future video transport phase can replace JPEG payloads with hardware-encoded H.264 or HEVC frames without changing the mouse and keyboard control paths.
