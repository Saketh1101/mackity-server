import SwiftUI

#if os(iOS)
struct RemoteScreenView: View {
    @StateObject private var viewModel: RemoteScreenViewModel
    @ObservedObject private var client: MacRemoteClient

    init(client: MacRemoteClient) {
        _viewModel = StateObject(wrappedValue: RemoteScreenViewModel(client: client))
        self.client = client
    }

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            screenCanvas
        }
        .navigationTitle("Remote Screen")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if client.isConnected {
                viewModel.requestStream()
            }
        }
        .onChange(of: client.isConnected) { _, isConnected in
            if isConnected {
                viewModel.requestStream()
            }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Label(
                client.isConnected ? viewModel.statusMessage : client.statusMessage,
                systemImage: client.isConnected ? "display" : "wifi.slash"
            )
            .lineLimit(1)

            Spacer()

            if viewModel.frameCount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.frameCount) frames")
                    Text(String(format: "%.1f FPS | %.0f KB | %@", viewModel.averageFrameRate, viewModel.lastFrameKilobytes, viewModel.streamProfile))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var screenCanvas: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.medium)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ContentUnavailableView(
                        "Waiting for Screen",
                        systemImage: "display",
                        description: Text("Keep the Mac server running and allow Screen Recording permission if macOS asks.")
                    )
                    .foregroundStyle(.white)
                }
            }
        }
    }
}
#endif
