# MacRemote Phase 1

MacRemote is a SwiftUI multiplatform app with a macOS TCP server and an iOS Bonjour-discovery client.

## Project Structure

- `makity/Models`
  - `RemoteMessage.swift`: JSON message schema for `ping`, `pong`, `mouseMove`, `mouseClick`, `keyboardInput`, `screenshotRequest`, and `screenshotResponse`.
  - `DiscoveredMac.swift`: Bonjour discovery model.
- `makity/Networking`
  - `RemoteMessageCodec.swift`: Length-prefixed JSON frame encoder/decoder for TCP streams.
  - `RemoteConnection.swift`: Shared `NWConnection` wrapper.
  - `MacRemoteServer.swift`: macOS `NWListener` server with Bonjour advertising.
  - `MacDiscoveryBrowser.swift`: iOS Bonjour browser.
  - `MacRemoteClient.swift`: iOS TCP client.
- `makity/Services`
  - `RemoteControlService.swift`: Phase 1 message handling. Later phases will add mouse, keyboard, and screen actions here.
- `makity/ViewModels`
  - `MacServerViewModel.swift`: macOS server screen state.
  - `iPhoneDiscoveryViewModel.swift`: iOS discovery and connection state.
- `makity/Views`
  - `MacServerView.swift`: macOS server UI.
  - `iPhoneDiscoveryView.swift`: iOS discovery UI.
- `makity/Utilities`
  - `DeviceInfoProvider.swift`: Device name and local IPv4 lookup.

## Architecture

The app uses MVVM over Apple's Network Framework. TCP messages are encoded as JSON and framed with a 4-byte big-endian payload length, which avoids message-boundary bugs on stream sockets.

Phase 1 implements transport and discovery. The later message types are already in the protocol so Phase 2-4 can add behavior without changing the wire format.

## Required Xcode Target Settings

Because this project uses generated Info.plists, set these in the target's Build Settings:

- `Product Name`: `MacRemote`
- `Swift Language Version`: `Swift 6`
- `Info.plist Key: CFBundleDisplayName`: `MacRemote`
- `Info.plist Key: CFBundleName`: `MacRemote`
- `Info.plist Key: NSBonjourServices`: `_macremote._tcp`
- `Info.plist Key: NSLocalNetworkUsageDescription`: `MacRemote discovers and connects to Macs on your local Wi-Fi network.`

For macOS sandboxed builds, enable these capabilities:

- App Sandbox
- Outgoing Connections (Client)
- Incoming Connections (Server)

The file `makity/MacRemote.entitlements` contains the matching macOS sandbox network entitlements.

## Build And Run

1. Select a macOS run destination and run the app.
2. Click `Start Server`.
3. Select an iPhone or iOS Simulator run destination and run the app.
4. The iPhone app automatically browses for `_macremote._tcp` Bonjour services.
5. Tap `Connect` next to the Mac. The client sends `ping`; the Mac replies with `pong`.

