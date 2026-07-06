import SwiftUI

#if os(macOS)
struct MacServerView: View {
    @StateObject private var viewModel = MacServerViewModel()

    private var accessibilityGranted: Bool {
        viewModel.server.accessibilityStatusMessage.contains("granted")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            if !accessibilityGranted {
                accessibilityWarning
            }
            serverDetails
            controls
            if viewModel.availableDisplayCount > 1 {
                displayPicker
            }
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

    private var accessibilityWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Mouse & Keyboard Control Blocked")
                    .font(.headline)
                Text("Go to System Settings → Privacy & Security → Accessibility and enable Makity.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.server.requestAccessibilityPermission()
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            } label: {
                Text("Open Settings")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(14)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.orange.opacity(0.35), lineWidth: 1))
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

    private var displayPicker: some View {
        HStack(spacing: 12) {
            Text("Display")
                .foregroundStyle(.secondary)

            Picker("Display", selection: $viewModel.selectedDisplayIndex) {
                ForEach(0..<viewModel.availableDisplayCount, id: \.self) { i in
                    Text("Display \(i + 1)").tag(i)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
            .onChange(of: viewModel.selectedDisplayIndex) { _, newIndex in
                viewModel.switchDisplay(to: newIndex)
            }
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
