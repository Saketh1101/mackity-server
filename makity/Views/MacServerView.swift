import SwiftUI

#if os(macOS)
struct MacServerView: View {
    @StateObject private var viewModel = MacServerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            serverDetails
            controls
            connectionSummary
            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(minWidth: 520, minHeight: 360)
        .onAppear {
            viewModel.refreshNetworkInfo()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MacRemote")
                .font(.largeTitle.bold())
            Text("Local Wi-Fi remote control server")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var serverDetails: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            detailRow(title: "Device", value: viewModel.deviceName)
            detailRow(title: "Local IP", value: viewModel.localIPAddress)
            detailRow(title: "Bonjour", value: MacRemoteService.bonjourType)
            detailRow(title: "Status", value: viewModel.server.statusMessage)
            detailRow(title: "Screen", value: viewModel.server.streamingStatusMessage)
            detailRow(title: "Mouse", value: viewModel.server.accessibilityStatusMessage)
        }
        .textSelection(.enabled)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.toggleServer()
            } label: {
                Label(
                    viewModel.server.isRunning ? "Stop Server" : "Start Server",
                    systemImage: viewModel.server.isRunning ? "stop.circle" : "play.circle"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                viewModel.refreshNetworkInfo()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .controlSize(.large)

            Button {
                viewModel.server.requestAccessibilityPermission()
            } label: {
                Label("Mouse Permission", systemImage: "cursorarrow.motionlines")
            }
            .controlSize(.large)
        }
    }

    private var connectionSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Connected clients: \(viewModel.server.connectedClientCount)", systemImage: "iphone")
                .font(.headline)

            if let message = viewModel.server.lastReceivedMessage {
                Text("Last message: \(message.type.rawValue)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("No messages received yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private func detailRow(title: String, value: String) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MacServerView()
}
#endif
