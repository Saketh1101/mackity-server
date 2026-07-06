import SwiftUI

#if os(iOS)
import UIKit

struct TouchpadSurface: UIViewRepresentable {
    let isDragModeEnabled: () -> Bool
    let onMove: (Double, Double) -> Void
    let onScroll: (Double, Double) -> Void
    let onClick: (Int) -> Void
    let onRightClick: () -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true

        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        singleTap.require(toFail: doubleTap)

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        singleTap.require(toFail: longPress)

        let movePan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMovePan(_:)))
        movePan.minimumNumberOfTouches = 1
        movePan.maximumNumberOfTouches = 1
        movePan.delegate = context.coordinator

        let scrollPan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleScrollPan(_:)))
        scrollPan.minimumNumberOfTouches = 2
        scrollPan.maximumNumberOfTouches = 2
        scrollPan.delegate = context.coordinator

        view.addGestureRecognizer(singleTap)
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(longPress)
        view.addGestureRecognizer(movePan)
        view.addGestureRecognizer(scrollPan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let parent: TouchpadSurface
        private var dragIsActive = false

        init(parent: TouchpadSurface) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            parent.onClick(recognizer.numberOfTapsRequired)
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began else { return }
            parent.onRightClick()
        }

        @objc func handleMovePan(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: recognizer.view)

            switch recognizer.state {
            case .began:
                if parent.isDragModeEnabled() {
                    dragIsActive = true
                    parent.onDragStart()
                }
            case .changed:
                guard translation != .zero else { return }
                parent.onMove(translation.x, translation.y)
                recognizer.setTranslation(.zero, in: recognizer.view)
            case .ended, .cancelled, .failed:
                if dragIsActive {
                    parent.onDragEnd()
                    dragIsActive = false
                }
            default:
                break
            }
        }

        @objc func handleScrollPan(_ recognizer: UIPanGestureRecognizer) {
            guard recognizer.state == .changed else { return }
            let translation = recognizer.translation(in: recognizer.view)
            guard translation != .zero else { return }
            parent.onScroll(translation.x, translation.y)
            recognizer.setTranslation(.zero, in: recognizer.view)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }
    }
}
#endif
