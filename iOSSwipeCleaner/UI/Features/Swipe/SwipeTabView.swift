import SwiftUI

struct SwipeTabView: View {
    @ObservedObject var viewModel: SwipeViewModel
    let trashCount: Int
    let onOpenAlbumSelector: () -> Void
    let onCardTap: (String) -> Void
    let onEmptyTrash: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text("SwipeCleaner")
                .font(.system(size: 24, weight: .black))
                .tracking(1)
                .foregroundColor(.white)
                .padding(.top, 12)
            albumChip
            progress
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 16)
            if showsDeck {
                Text("◀ Swipe left to trash | Tap to zoom | Swipe right to keep ▶")
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 24)
    }

    private var showsDeck: Bool {
        !viewModel.isLoading && !viewModel.photoPool.isEmpty && !viewModel.isSessionFinished
    }

    private var albumChip: some View {
        Button(action: onOpenAlbumSelector) {
            HStack(spacing: 4) {
                Text(viewModel.selectedAlbum?.name ?? "All Photos")
                    .font(.system(size: 14, weight: .bold))
                Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .accessibilityLabel("Folder: \(viewModel.selectedAlbum?.name ?? "All Photos")")
        .accessibilityHint("Choose a folder to review")
    }

    @ViewBuilder
    private var progress: some View {
        if showsDeck {
            Text("Progress: \(min(viewModel.currentIndex + 1, viewModel.photoPool.count)) / \(viewModel.photoPool.count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.secondaryText)
        } else {
            Color.clear.frame(height: 18)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            VStack(spacing: 16) {
                ProgressView().tint(Theme.primary)
                Text("Loading gallery pool…").foregroundColor(Theme.secondaryText)
            }
        } else if viewModel.photoPool.isEmpty {
            SessionFinishedView(
                mode: .empty,
                deleteQueueSize: trashCount,
                onEmptyTrash: onEmptyTrash,
                onSeeKept: { viewModel.setActiveTab(.kept) }
            )
        } else if viewModel.isSessionFinished {
            SessionFinishedView(
                mode: .finished(totalReviewed: viewModel.photoPool.count, kept: viewModel.keptCount),
                deleteQueueSize: trashCount,
                onEmptyTrash: onEmptyTrash,
                onSeeKept: { viewModel.setActiveTab(.kept) }
            )
        } else {
            SwipeDeckView(
                photoPool: viewModel.photoPool,
                currentIndex: viewModel.currentIndex,
                onSwipeLeft: { Task { await viewModel.swipeLeft() } },
                onSwipeRight: { Task { await viewModel.swipeRight() } },
                onCardTap: onCardTap
            )
        }
    }
}
