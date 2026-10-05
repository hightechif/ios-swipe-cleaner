import SwiftUI

/// Full-screen photo with pinch-to-zoom and pan. Tap at normal scale, or the close button, dismisses.
struct FullscreenImageViewer: View {
    let photoId: String
    let onClose: () -> Void

    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                PhotoImageView(photoId: photoId, fill: false, sizeMultiplier: 2, background: .black)
                    .ignoresSafeArea()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(zoom.simultaneously(with: pan(in: geometry.size)))
                    .onTapGesture(count: 2) { reset() }
                    .onTapGesture { if scale <= 1.01 { onClose() } }
                    .accessibilityLabel("Fullscreen photo")
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .padding(16)
                .accessibilityLabel("Close")
            }
        }
    }

    private var zoom: some Gesture {
        MagnificationGesture()
            .onChanged { scale = max(1, min(committedScale * $0, 6)) }
            .onEnded { _ in
                committedScale = scale
                if scale <= 1.01 { reset() }
            }
    }

    private func pan(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = clamped(
                    CGSize(width: committedOffset.width + value.translation.width,
                           height: committedOffset.height + value.translation.height),
                    in: size
                )
            }
            .onEnded { _ in committedOffset = offset }
    }

    private func clamped(_ proposed: CGSize, in size: CGSize) -> CGSize {
        let maxX = size.width * (scale - 1) / 2
        let maxY = size.height * (scale - 1) / 2
        return CGSize(width: min(max(proposed.width, -maxX), maxX), height: min(max(proposed.height, -maxY), maxY))
    }

    private func reset() {
        withAnimation(.spring()) {
            scale = 1
            committedScale = 1
            offset = .zero
            committedOffset = .zero
        }
    }
}
