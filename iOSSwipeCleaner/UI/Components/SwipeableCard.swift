import SwiftUI
import UIKit

/// The draggable photo card. Swiping past 35% of the screen width commits a decision.
struct SwipeableCard: View {
    let photoId: String
    var isInteractive = true
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onTap: () -> Void

    @State private var offsetX: CGFloat = 0
    @State private var isCommitting = false

    private let screenWidth = UIScreen.main.bounds.width
    private var threshold: CGFloat { screenWidth * 0.35 }
    private var dragProgress: CGFloat { min(1, abs(offsetX) / threshold) }

    var body: some View {
        ZStack {
            PhotoImageView(photoId: photoId)
            if offsetX != 0 { overlay }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        .offset(x: offsetX)
        .rotationEffect(.degrees(Double(offsetX / screenWidth) * 15))
        .scaleEffect(min(1, 1 - (abs(offsetX) / screenWidth) * 0.05))
        .contentShape(Rectangle())
        .onTapGesture { if isInteractive { onTap() } }
        .gesture(isInteractive && !isCommitting ? dragGesture : nil)
    }

    private var overlay: some View {
        let isKeep = offsetX > 0
        let color = isKeep ? Theme.keep : Theme.delete
        return ZStack {
            color.opacity(Double(dragProgress) * 0.4)
            Image(systemName: isKeep ? "heart.fill" : "trash.fill")
                .font(.system(size: 36))
                .foregroundColor(color)
                .padding(24)
                .background(Circle().fill(Color.black.opacity(0.6)))
                .scaleEffect(1 + dragProgress * 0.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { offsetX = $0.translation.width }
            .onEnded { value in
                let travelled = value.translation.width
                if travelled > threshold {
                    commit(direction: 1, action: onSwipeRight)
                } else if travelled < -threshold {
                    commit(direction: -1, action: onSwipeLeft)
                } else {
                    withAnimation(.spring()) { offsetX = 0 }
                }
            }
    }

    private func commit(direction: CGFloat, action: @escaping () -> Void) {
        isCommitting = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring()) { offsetX = direction * screenWidth * 1.2 }
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            action()
        }
    }
}
