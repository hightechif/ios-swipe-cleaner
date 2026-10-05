import SwiftUI

private struct ViewerItem: Identifiable {
    let id: String
}

private enum ActiveAlert: Identifiable {
    case milestone
    case restoreKeptPhoto(String)
    case restoreTrashPhoto(String)
    case restoreAllKept

    var id: String {
        switch self {
        case .milestone: return "milestone"
        case .restoreKeptPhoto(let id): return "kept-\(id)"
        case .restoreTrashPhoto(let id): return "trash-\(id)"
        case .restoreAllKept: return "all-kept"
        }
    }
}

struct MainView: View {
    @ObservedObject var swipeViewModel: SwipeViewModel
    @ObservedObject var trashViewModel: TrashViewModel
    @ObservedObject var keptViewModel: KeptPhotosViewModel
    let isLimitedAccess: Bool
    let onManageSelection: () -> Void

    @State private var viewerItem: ViewerItem?
    @State private var showAlbumSelector = false
    @State private var pendingAlert: ActiveAlert?

    private var visibleAlert: ActiveAlert? {
        pendingAlert ?? (swipeViewModel.showMilestoneDialog ? .milestone : nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLimitedAccess {
                LimitedAccessBanner(onManage: onManageSelection).padding(.top, 8)
            }
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            SwipeBottomBar(
                activeTab: swipeViewModel.activeTab,
                keptCount: keptViewModel.keptPhotos.count,
                trashCount: trashViewModel.deleteQueue.count,
                onSelect: swipeViewModel.setActiveTab
            )
        }
        .task { await swipeViewModel.start() }
        .task(id: swipeViewModel.activeTab) {
            if swipeViewModel.activeTab == .kept { await keptViewModel.refreshMediaImages() }
        }
        .fullScreenCover(item: $viewerItem) { item in
            FullscreenImageViewer(photoId: item.id) { viewerItem = nil }
        }
        .sheet(isPresented: $showAlbumSelector) {
            AlbumSelectorSheet(
                albums: swipeViewModel.albums,
                selectedAlbumId: swipeViewModel.selectedAlbum?.id,
                onSelect: { album in
                    showAlbumSelector = false
                    Task { await swipeViewModel.selectAlbum(album) }
                },
                onDismiss: { showAlbumSelector = false }
            )
        }
        .alert(
            alertTitle,
            isPresented: Binding(get: { visibleAlert != nil }, set: { if !$0 { dismissAlert() } }),
            presenting: visibleAlert,
            actions: alertActions,
            message: { Text(alertMessage(for: $0)) }
        )
    }

    @ViewBuilder
    private var tabContent: some View {
        switch swipeViewModel.activeTab {
        case .swipe:
            SwipeTabView(
                viewModel: swipeViewModel,
                trashCount: trashViewModel.deleteQueue.count,
                onOpenAlbumSelector: { showAlbumSelector = true },
                onCardTap: { viewerItem = ViewerItem(id: $0) },
                onEmptyTrash: emptyTrash
            )
        case .kept:
            KeptTabView(
                keptPhotos: keptViewModel.keptPhotos,
                keptAlbums: keptViewModel.keptAlbums,
                onPhotoTap: { viewerItem = ViewerItem(id: $0) },
                onPhotoLongPress: { pendingAlert = .restoreKeptPhoto($0) },
                onResetAll: { pendingAlert = .restoreAllKept }
            )
        case .trash:
            TrashTabView(
                deleteQueue: trashViewModel.deleteQueue,
                onPhotoTap: { pendingAlert = .restoreTrashPhoto($0) },
                onViewPhoto: { viewerItem = ViewerItem(id: $0) },
                onDelete: emptyTrash
            )
        }
    }

    // MARK: - Alerts

    private var alertTitle: String {
        switch visibleAlert {
        case .milestone: return "Milestone Reached! 🎯"
        case .restoreKeptPhoto: return "Reset Photo?"
        case .restoreTrashPhoto: return "Restore Photo?"
        case .restoreAllKept: return "Restore All Kept Photos?"
        case nil: return ""
        }
    }

    private func alertMessage(for alert: ActiveAlert) -> String {
        switch alert {
        case .milestone:
            return "You have swiped \(swipeViewModel.sessionSwipeCount) photos in this session. Would you like to review them now or empty your trash?"
        case .restoreKeptPhoto:
            return "Do you want to reset this photo? It will be removed from Kept and put back on your swipe deck."
        case .restoreTrashPhoto:
            return "Do you want to restore this photo back to your active swipe deck?"
        case .restoreAllKept:
            return "This will clear all your kept photos. They will reappear in your swipe deck from the beginning."
        }
    }

    @ViewBuilder
    private func alertActions(for alert: ActiveAlert) -> some View {
        switch alert {
        case .milestone:
            Button("Review Trash (\(trashViewModel.deleteQueue.count))") {
                swipeViewModel.dismissMilestoneDialog()
                swipeViewModel.setActiveTab(.trash)
            }
            if !trashViewModel.deleteQueue.isEmpty {
                Button("Empty Trash") {
                    swipeViewModel.dismissMilestoneDialog()
                    emptyTrash()
                }
            }
            Button("Keep Swiping", role: .cancel) { swipeViewModel.dismissMilestoneDialog() }
        case .restoreKeptPhoto(let id):
            Button("Reset", role: .destructive) {
                Task {
                    if await keptViewModel.restoreKeptPhoto(id: id) {
                        swipeViewModel.onPhotoRestored(id: id, wasKept: true)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        case .restoreTrashPhoto(let id):
            Button("Restore") {
                Task {
                    if await trashViewModel.restoreFromTrash(id: id) {
                        swipeViewModel.onPhotoRestored(id: id, wasKept: false)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        case .restoreAllKept:
            Button("Restore All", role: .destructive) {
                Task {
                    if await keptViewModel.resetProgress() {
                        await swipeViewModel.onAllKeptPhotosReset()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func dismissAlert() {
        pendingAlert = nil
        swipeViewModel.dismissMilestoneDialog()
    }

    private func emptyTrash() {
        Task { await trashViewModel.executeTrashRequest() }
    }
}
