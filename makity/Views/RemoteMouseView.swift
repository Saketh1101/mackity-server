import SwiftUI

#if os(iOS)
struct RemoteMouseView: View {
    @StateObject private var viewModel: RemoteMouseViewModel
    @ObservedObject private var client: MacRemoteClient

    init(client: MacRemoteClient) {
        _viewModel = StateObject(wrappedValue: RemoteMouseViewModel(client: client))
        self.client = client
    }

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            touchpad
        }
        .navigationTitle("Touchpad")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Label(
                client.isConnected ? viewModel.statusMessage : client.statusMessage,
                systemImage: client.isConnected ? "cursorarrow.motionlines" : "wifi.slash"
            )
            .lineLimit(1)

            Spacer()

            Toggle(isOn: $viewModel.isDragModeEnabled) {
                Label("Drag", systemImage: "hand.draw")
            }
            .toggleStyle(.button)
            .disabled(!client.isConnected)
        }
        .font(.footnote)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var touchpad: some View {
        ZStack {
            Rectangle()
                .fill(.background)

            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.secondary.opacity(0.25), lineWidth: 1)
                .padding(18)

            Image(systemName: viewModel.isDragModeEnabled ? "hand.draw" : "cursorarrow.motionlines")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(.secondary.opacity(0.35))

            TouchpadSurface(
                isDragModeEnabled: { viewModel.isDragModeEnabled },
                onMove: { deltaX, deltaY in
                    guard client.isConnected else { return }
                    viewModel.move(deltaX: deltaX, deltaY: deltaY)
                },
                onScroll: { deltaX, deltaY in
                    guard client.isConnected else { return }
                    viewModel.scroll(deltaX: deltaX, deltaY: deltaY)
                },
                onClick: { clickCount in
                    guard client.isConnected else { return }
                    viewModel.click(clickCount: clickCount)
                },
                onDragStart: {
                    guard client.isConnected else { return }
                    viewModel.beginDrag()
                },
                onDragEnd: {
                    guard client.isConnected else { return }
                    viewModel.endDrag()
                }
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
#endif
