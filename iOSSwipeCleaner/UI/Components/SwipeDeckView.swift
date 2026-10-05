import SwiftUI

/// The current card with the next one waiting behind it. Images for the following cards are prefetched.
struct SwipeDeckView: View {
    @EnvironmentObject private var imageLoader: ImageLoader

    let photoPool: [String]
    let currentIndex: Int
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onCardTap: (String) -> Void

    private let prefetchCount = 3

    private var visibleIds: [String] {
        guard currentIndex < photoPool.count else { return [] }
        let end = min(currentIndex + 2, photoPool.count)
        // Back card first so the current card draws on top.
        return Array(photoPool[currentIndex..<end]).reversed()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(visibleIds, id: \.self) { id in
                    let isTop = id == photoPool[currentIndex]
                    SwipeableCard(
                        photoId: id,
                        isInteractive: isTop,
                        onSwipeLeft: onSwipeLeft,
                        onSwipeRight: onSwipeRight,
                        onTap: { onCardTap(id) }
                    )
                    .scaleEffect(isTop ? 1 : 0.94)
                    .opacity(isTop ? 1 : 0.7)
                    .animation(.spring(), value: isTop)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Photo \(currentIndex + 1) of \(photoPool.count)")
                    .accessibilityHint("Swipe left to delete, right to keep, or use the actions.")
                    .accessibilityAddTraits(.isImage)
                    .accessibilityHidden(!isTop)
                    .accessibilityAction(named: "Keep") { if isTop { onSwipeRight() } }
                    .accessibilityAction(named: "Delete") { if isTop { onSwipeLeft() } }
                    .accessibilityAction(named: "View full screen") { if isTop { onCardTap(id) } }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .task(id: currentIndex) { prefetch(size: geometry.size) }
        }
    }

    private func prefetch(size: CGSize) {
        let end = min(currentIndex + 1 + prefetchCount, photoPool.count)
        guard currentIndex + 1 < end else { return }
        let ids = Array(photoPool[(currentIndex + 1)..<end])
        imageLoader.startCaching(ids: ids, pixelSize: ImageLoader.pixelSize(for: size))
    }
}
