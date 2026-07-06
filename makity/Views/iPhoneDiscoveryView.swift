import SwiftUI

#if os(iOS)
struct PhoneDiscoveryView: View {
    @StateObject private var viewModel = PhoneDiscoveryViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusView
                }

                if viewModel.client.isConnected {
                    Section {
                        NavigationLink {
                            RemoteScreenView(client: viewModel.client)
                        } label: {
                            Label("Open Remote Screen", systemImage: "display")
                        }

                        NavigationLink {
                            RemoteMouseView(client: viewModel.client)
                        } label: {
                            Label("Open Touchpad", systemImage: "cursorarrow.motionlines")
                        }

                        NavigationLink {
                            RemoteKeyboardView(client: viewModel.client)
                        } label: {
                            Label("Open Keyboard", systemImage: "keyboard")
                        }
                    }
                }

                Section("Available Macs") {
                    if viewModel.availableMacs.isEmpty {
                        ContentUnavailableView(
                            "No Macs Found",
                            systemImage: "macbook.and.iphone",
                            description: Text("Start the MacRemote server on a Mac connected to this Wi-Fi network.")
                        )
                    } else {
                        ForEach(viewModel.availableMacs) { mac in
                            macRow(mac)
                        }
                    }
                }
            }
            .navigationTitle("MacRemote")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if viewModel.discovery.isBrowsing {
                            viewModel.stopDiscovery()
                        } else {
                            viewModel.startDiscovery()
                        }
                    } label: {
                        Image(systemName: viewModel.discovery.isBrowsing ? "pause.circle" : "arrow.clockwise")
                    }
                    .accessibilityLabel(viewModel.discovery.isBrowsing ? "Stop discovery" : "Start discovery")
                }
            }
        }
        .onAppear { viewModel.startDiscovery() }
        .onDisappear { viewModel.stopDiscovery() }
    }

    private var statusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(viewModel.discovery.statusMessage, systemImage: "dot.radiowaves.left.and.right")

            HStack(spacing: 8) {
                if viewModel.client.isReconnecting {
                    ProgressView()
                        .scaleEffect(0.75)
                }
                Label(
                    viewModel.client.statusMessage,
                    systemImage: viewModel.client.isConnected ? "checkmark.circle" : "link"
                )
                .foregroundStyle(viewModel.client.isConnected ? .green : .secondary)
            }

            if viewModel.client.isConnected || viewModel.client.isReconnecting {
                Button(role: .destructive) {
                    viewModel.disconnect()
                } label: {
                    Label("Disconnect", systemImage: "xmark.circle")
                }
            }
        }
        .font(.callout)
    }

    private func macRow(_ mac: DiscoveredMac) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "desktopcomputer")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(mac.name)
                    .font(.headline)
                Text(mac.endpoint.stableIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                viewModel.connect(to: mac)
            } label: {
                Text(viewModel.selectedMac == mac && viewModel.client.isConnected ? "Connected" : "Connect")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedMac == mac && viewModel.client.isConnected)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    PhoneDiscoveryView()
}
#endif
