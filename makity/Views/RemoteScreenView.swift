import SwiftUI

#if os(iOS)
import UIKit

struct RemoteScreenView: View {
    @StateObject private var viewModel: RemoteScreenViewModel
    @ObservedObject private var client: MacRemoteClient
    @Environment(\.dismiss) private var dismiss

    init(client: MacRemoteClient) {
        _viewModel = StateObject(wrappedValue: RemoteScreenViewModel(client: client))
        self.client = client
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.medium)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .allowsHitTesting(false)

                    ScreenInteractionSurface(
                        onTap: { point in
                            viewModel.absoluteClick(at: point, in: proxy.size)
                        },
                        onLongPress: { point in
                            viewModel.absoluteClick(at: point, in: proxy.size, button: .right)
                        },
                        onPan: { point in
                            viewModel.absoluteMove(at: point, in: proxy.size)
                        },
                        onScroll: { dx, dy in
                            viewModel.screenScroll(deltaX: dx, deltaY: dy)
                        }
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ContentUnavailableView(
                        "Waiting for Screen",
                        systemImage: "display",
                        description: Text("Keep the Mac server running and allow Screen Recording permission if macOS asks.")
                    )
                    .foregroundStyle(.white)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }

                topOverlay
            }
        }
        .background(Color.black.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if client.isConnected { viewModel.requestStream() }
        }
        .onChange(of: client.isConnected) { _, isConnected in
            if isConnected { viewModel.requestStream() }
        }
    }

    private var topOverlay: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("End")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.red.opacity(0.8), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(client.isConnected ? viewModel.statusMessage : client.statusMessage)
                    .font(.caption2)
                    .foregroundStyle(.white)
                if viewModel.frameCount > 0 {
                    Text(String(format: "%.1f FPS  ·  %.0f KB  ·  %@",
                                viewModel.averageFrameRate,
                                viewModel.lastFrameKilobytes,
                                viewModel.streamProfile))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            if viewModel.macDisplayCount > 1 {
                Picker("Display", selection: $viewModel.selectedDisplayIndex) {
                    ForEach(0..<viewModel.macDisplayCount, id: \.self) { i in
                        Text("Display \(i + 1)").tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .onChange(of: viewModel.selectedDisplayIndex) { _, newIndex in
                    viewModel.switchDisplay(to: newIndex)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Screen interaction gesture surface

private struct ScreenInteractionSurface: UIViewRepresentable {
    let onTap: (CGPoint) -> Void
    let onLongPress: (CGPoint) -> Void
    let onPan: (CGPoint) -> Void
    let onScroll: (Double, Double) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.6
        tap.require(toFail: longPress)

        let movePan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMovePan(_:)))
        movePan.minimumNumberOfTouches = 1
        movePan.maximumNumberOfTouches = 1
        movePan.delegate = context.coordinator

        let scrollPan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleScrollPan(_:)))
        scrollPan.minimumNumberOfTouches = 2
        scrollPan.maximumNumberOfTouches = 2
        scrollPan.delegate = context.coordinator

        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(longPress)
        view.addGestureRecognizer(movePan)
        view.addGestureRecognizer(scrollPan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let parent: ScreenInteractionSurface

        init(parent: ScreenInteractionSurface) { self.parent = parent }

        @objc func handleTap(_ r: UITapGestureRecognizer) {
            guard r.state == .ended else { return }
            parent.onTap(r.location(in: r.view))
        }

        @objc func handleLongPress(_ r: UILongPressGestureRecognizer) {
            guard r.state == .began else { return }
            parent.onLongPress(r.location(in: r.view))
        }

        @objc func handleMovePan(_ r: UIPanGestureRecognizer) {
            guard r.state == .changed || r.state == .began else { return }
            parent.onPan(r.location(in: r.view))
        }

        @objc func handleScrollPan(_ r: UIPanGestureRecognizer) {
            guard r.state == .changed else { return }
            let t = r.translation(in: r.view)
            guard t != .zero else { return }
            parent.onScroll(t.x, t.y)
            r.setTranslation(.zero, in: r.view)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool { false }
    }
}
#endif
