import SwiftUI

#if os(iOS)
struct RemoteKeyboardView: View {
    @StateObject private var viewModel: RemoteKeyboardViewModel
    @ObservedObject private var client: MacRemoteClient
    @FocusState private var inputIsFocused: Bool

    private let shortcutColumns = [GridItem(.adaptive(minimum: 84), spacing: 10)]
    private let mediaColumns    = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    init(client: MacRemoteClient) {
        _viewModel = StateObject(wrappedValue: RemoteKeyboardViewModel(client: client))
        self.client = client
    }

    var body: some View {
        Form {
            Section { statusView }

            Section("Text Input") { textInputSection }

            Section("Special Keys") { specialKeysSection }

            Section("Command Shortcuts") { commandShortcutsSection }

            Section("Media & Volume") { mediaSection }

            Section("Clipboard") { clipboardSection }
        }
        .navigationTitle("Keyboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { inputIsFocused = true } label: {
                    Image(systemName: "keyboard")
                }
                .accessibilityLabel("Focus keyboard input")
            }
        }
        .onAppear { inputIsFocused = true }
    }

    // MARK: - Sections

    private var statusView: some View {
        Label(
            client.isConnected ? viewModel.statusMessage : client.statusMessage,
            systemImage: client.isConnected ? "keyboard" : "wifi.slash"
        )
        .foregroundStyle(client.isConnected ? .primary : .secondary)
    }

    private var textInputSection: some View {
        Group {
            TextField("Type here", text: $viewModel.inputText, axis: .vertical)
                .focused($inputIsFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(3...6)
                .onChange(of: viewModel.inputText) { _, newValue in
                    guard client.isConnected else { return }
                    viewModel.handleTextChange(newValue)
                }
                .onSubmit {
                    guard client.isConnected else { return }
                    viewModel.sendSpecialKey(.enter)
                }

            Button {
                viewModel.clearInput()
                inputIsFocused = true
            } label: {
                Label("Clear Local Field", systemImage: "xmark.circle")
            }
        }
    }

    private var specialKeysSection: some View {
        Group {
            arrowPad

            HStack(spacing: 10) {
                keyButton("Enter", systemImage: "return") { viewModel.sendSpecialKey(.enter) }
                keyButton("Delete", systemImage: "delete.left") { viewModel.sendSpecialKey(.delete) }
            }

            HStack(spacing: 10) {
                keyButton("Tab", systemImage: "arrow.right.to.line") { viewModel.sendSpecialKey(.tab) }
                keyButton("Escape", systemImage: "escape") { viewModel.sendSpecialKey(.escape) }
            }
        }
    }

    private var commandShortcutsSection: some View {
        LazyVGrid(columns: shortcutColumns, spacing: 10) {
            shortcutButton("Cmd C", keyCode: 8)
            shortcutButton("Cmd V", keyCode: 9)
            shortcutButton("Cmd X", keyCode: 7)
            shortcutButton("Cmd A", keyCode: 0)
            shortcutButton("Cmd Z", keyCode: 6)
            shortcutButton("Cmd S", keyCode: 1)
        }
    }

    private var mediaSection: some View {
        Group {
            LazyVGrid(columns: mediaColumns, spacing: 10) {
                mediaButton("Vol −", systemImage: "speaker.minus.fill")  { viewModel.sendMediaKey(.volumeDown) }
                mediaButton("Mute",  systemImage: "speaker.slash.fill")  { viewModel.sendMediaKey(.mute) }
                mediaButton("Vol +", systemImage: "speaker.plus.fill")   { viewModel.sendMediaKey(.volumeUp) }
            }
            LazyVGrid(columns: mediaColumns, spacing: 10) {
                mediaButton("Prev",       systemImage: "backward.fill")  { viewModel.sendMediaKey(.previousTrack) }
                mediaButton("Play/Pause", systemImage: "playpause.fill") { viewModel.sendMediaKey(.playPause) }
                mediaButton("Next",       systemImage: "forward.fill")   { viewModel.sendMediaKey(.nextTrack) }
            }
            LazyVGrid(columns: mediaColumns, spacing: 10) {
                mediaButton("Brt −", systemImage: "sun.min.fill") { viewModel.sendMediaKey(.brightnessDown) }
                Color.clear
                mediaButton("Brt +", systemImage: "sun.max.fill") { viewModel.sendMediaKey(.brightnessUp) }
            }
        }
        .disabled(!client.isConnected)
    }

    private var clipboardSection: some View {
        Group {
            Button {
                guard client.isConnected else { return }
                viewModel.pushClipboard()
            } label: {
                Label("Send iPhone Clipboard → Mac", systemImage: "arrow.up.doc.on.clipboard")
            }
            .disabled(!client.isConnected)

            Button {
                guard client.isConnected else { return }
                viewModel.pullClipboard()
            } label: {
                Label("Get Mac Clipboard → iPhone", systemImage: "arrow.down.doc.on.clipboard")
            }
            .disabled(!client.isConnected)

            if let text = viewModel.receivedClipboard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)

                    HStack(spacing: 12) {
                        Button {
                            viewModel.copyReceivedClipboard()
                        } label: {
                            Label("Copy to iPhone", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button(role: .destructive) {
                            viewModel.clearReceivedClipboard()
                        } label: {
                            Label("Clear", systemImage: "xmark")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    // MARK: - Reusable button builders

    private var arrowPad: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                Color.clear.frame(height: 44)
                keyButton("Up", systemImage: "arrow.up") { viewModel.sendSpecialKey(.arrowUp) }
                Color.clear.frame(height: 44)
            }
            GridRow {
                keyButton("Left",  systemImage: "arrow.left")  { viewModel.sendSpecialKey(.arrowLeft) }
                keyButton("Down",  systemImage: "arrow.down")  { viewModel.sendSpecialKey(.arrowDown) }
                keyButton("Right", systemImage: "arrow.right") { viewModel.sendSpecialKey(.arrowRight) }
            }
        }
        .disabled(!client.isConnected)
    }

    private func shortcutButton(_ title: String, keyCode: UInt16) -> some View {
        Button { viewModel.sendShortcut(keyCode: keyCode, label: title) } label: {
            Text(title).frame(maxWidth: .infinity, minHeight: 38)
        }
        .buttonStyle(.bordered)
        .disabled(!client.isConnected)
    }

    private func keyButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage).frame(maxWidth: .infinity, minHeight: 38)
        }
        .buttonStyle(.bordered)
        .disabled(!client.isConnected)
    }

    private func mediaButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
    }
}
#endif
