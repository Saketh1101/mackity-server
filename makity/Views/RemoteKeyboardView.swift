import SwiftUI

#if os(iOS)
struct RemoteKeyboardView: View {
    @StateObject private var viewModel: RemoteKeyboardViewModel
    @ObservedObject private var client: MacRemoteClient
    @FocusState private var inputIsFocused: Bool

    private let shortcutColumns = [
        GridItem(.adaptive(minimum: 84), spacing: 10)
    ]

    init(client: MacRemoteClient) {
        _viewModel = StateObject(wrappedValue: RemoteKeyboardViewModel(client: client))
        self.client = client
    }

    var body: some View {
        Form {
            Section {
                statusView
            }

            Section("Text Input") {
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

            Section("Special Keys") {
                arrowPad

                HStack(spacing: 10) {
                    keyButton("Enter", systemImage: "return") {
                        viewModel.sendSpecialKey(.enter)
                    }

                    keyButton("Delete", systemImage: "delete.left") {
                        viewModel.sendSpecialKey(.delete)
                    }
                }
            }

            Section("Command Shortcuts") {
                LazyVGrid(columns: shortcutColumns, spacing: 10) {
                    shortcutButton("Cmd C", keyCode: 8)
                    shortcutButton("Cmd V", keyCode: 9)
                    shortcutButton("Cmd X", keyCode: 7)
                    shortcutButton("Cmd A", keyCode: 0)
                    shortcutButton("Cmd Z", keyCode: 6)
                    shortcutButton("Cmd S", keyCode: 1)
                }
            }
        }
        .navigationTitle("Keyboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    inputIsFocused = true
                } label: {
                    Image(systemName: "keyboard")
                }
                .accessibilityLabel("Focus keyboard input")
            }
        }
        .onAppear {
            inputIsFocused = true
        }
    }

    private var statusView: some View {
        Label(
            client.isConnected ? viewModel.statusMessage : client.statusMessage,
            systemImage: client.isConnected ? "keyboard" : "wifi.slash"
        )
        .foregroundStyle(client.isConnected ? .primary : .secondary)
    }

    private var arrowPad: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                Color.clear.frame(height: 44)
                keyButton("Up", systemImage: "arrow.up") {
                    viewModel.sendSpecialKey(.arrowUp)
                }
                Color.clear.frame(height: 44)
            }

            GridRow {
                keyButton("Left", systemImage: "arrow.left") {
                    viewModel.sendSpecialKey(.arrowLeft)
                }
                keyButton("Down", systemImage: "arrow.down") {
                    viewModel.sendSpecialKey(.arrowDown)
                }
                keyButton("Right", systemImage: "arrow.right") {
                    viewModel.sendSpecialKey(.arrowRight)
                }
            }
        }
        .disabled(!client.isConnected)
    }

    private func shortcutButton(_ title: String, keyCode: UInt16) -> some View {
        Button {
            viewModel.sendShortcut(keyCode: keyCode, label: title)
        } label: {
            Text(title)
                .frame(maxWidth: .infinity, minHeight: 38)
        }
        .buttonStyle(.bordered)
        .disabled(!client.isConnected)
    }

    private func keyButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, minHeight: 38)
        }
        .buttonStyle(.bordered)
        .disabled(!client.isConnected)
    }
}
#endif
