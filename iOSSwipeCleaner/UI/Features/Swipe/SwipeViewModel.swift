import Combine
import Foundation

enum SwipeTab: Equatable {
    case swipe, kept, trash
}

@MainActor
final class SwipeViewModel: ObservableObject {
    static let milestoneInterval = 50

    @Published private(set) var photoPool: [String] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var keptCount = 0
    @Published private(set) var isLoading = true
    @Published private(set) var isSessionFinished = false
    @Published private(set) var sessionSwipeCount = 0
    @Published private(set) var albums: [Album] = []
    @Published private(set) var selectedAlbum: Album?
    @Published private(set) var mediaImages: [MediaImage] = []
    @Published var showMilestoneDialog = false
    @Published var activeTab: SwipeTab = .swipe

    private let getShuffledPhotoPool: GetShuffledPhotoPoolUseCase
    private let markImageKept: MarkImageKeptUseCase
    private let addToTrash: AddToTrashUseCase
    private let getAllMediaImages: GetAllMediaImagesUseCase
    private let findExistingPhotoIds: FindExistingPhotoIdsUseCase
    private var hasStarted = false
    private var cancellables = Set<AnyCancellable>()

    init(
        getShuffledPhotoPool: GetShuffledPhotoPoolUseCase,
        markImageKept: MarkImageKeptUseCase,
        addToTrash: AddToTrashUseCase,
        getAllMediaImages: GetAllMediaImagesUseCase,
        findExistingPhotoIds: FindExistingPhotoIdsUseCase,
        getFilteredAlbums: GetFilteredAlbumsUseCase,
        getKeptPhotos: GetKeptPhotosUseCase,
        getTrashedPhotos: GetTrashedPhotosUseCase
    ) {
        self.getShuffledPhotoPool = getShuffledPhotoPool
        self.markImageKept = markImageKept
        self.addToTrash = addToTrash
        self.getAllMediaImages = getAllMediaImages
        self.findExistingPhotoIds = findExistingPhotoIds

        // Album counts follow decisions and library contents live.
        Publishers.CombineLatest3($mediaImages, getKeptPhotos(), getTrashedPhotos())
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .map { images, kept, trashed in
                getFilteredAlbums(
                    mediaImages: images,
                    keptIds: Set(kept.map(\.id)),
                    trashedIds: Set(trashed.map(\.id))
                )
            }
            .sink { [weak self] in self?.albums = $0 }
            .store(in: &cancellables)
    }

    var currentPhotoId: String? {
        photoPool.indices.contains(currentIndex) ? photoPool[currentIndex] : nil
    }

    /// Ids of the next `count` cards after the current one, for prefetching.
    func upcomingPhotoIds(count: Int) -> [String] {
        guard currentIndex + 1 < photoPool.count else { return [] }
        return Array(photoPool[(currentIndex + 1)..<min(photoPool.count, currentIndex + 1 + count)])
    }

    /// Loads the deck the first time the main screen appears.
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        await loadPhotoPool()
    }

    func loadPhotoPool() async {
        isLoading = true
        isSessionFinished = false
        let pool = await getShuffledPhotoPool(albumId: selectedAlbum?.id)
        photoPool = pool
        currentIndex = 0
        keptCount = 0
        sessionSwipeCount = 0
        showMilestoneDialog = false
        isLoading = false
        isSessionFinished = pool.isEmpty
        await loadMediaImages()
    }

    func loadMediaImages() async {
        mediaImages = await getAllMediaImages()
    }

    /// Reacts to photo library changes: refreshes album counts and drops cards whose photo is gone.
    /// A running session is never reshuffled, but an empty deck is reloaded so photos that just became
    /// available (e.g. after widening a limited selection) show up without a restart.
    func refreshAfterLibraryChange() async {
        await loadMediaImages()
        guard !isLoading else { return }
        if photoPool.isEmpty {
            await loadPhotoPool()
            return
        }
        guard currentIndex < photoPool.count else { return }
        let remaining = Array(photoPool[currentIndex...])
        let existing = await findExistingPhotoIds(ids: remaining)
        let missing = Set(remaining).subtracting(existing)
        guard !missing.isEmpty else { return }
        var pool = photoPool
        let tail = pool[min(currentIndex, pool.count)...].filter { !missing.contains($0) }
        pool.replaceSubrange(min(currentIndex, pool.count)..<pool.count, with: tail)
        photoPool = pool
        isSessionFinished = currentIndex >= pool.count
    }

    func selectAlbum(_ album: Album?) async {
        selectedAlbum = album
        await loadPhotoPool()
    }

    func swipeRight() async {
        guard let id = currentPhotoId else { return }
        keptCount += 1
        advance()
        do {
            try await markImageKept(id: id)
        } catch {
            AppLog.swipe.error("Failed to keep photo: \(error.localizedDescription)")
        }
    }

    func swipeLeft() async {
        guard let id = currentPhotoId else { return }
        advance()
        do {
            try await addToTrash(id: id)
        } catch {
            AppLog.swipe.error("Failed to stage photo for deletion: \(error.localizedDescription)")
        }
    }

    /// Puts a photo restored from Kept or Trash back into the deck at the current position.
    func onPhotoRestored(id: String, wasKept: Bool) {
        var pool = photoPool
        pool.insert(id, at: min(max(currentIndex, 0), pool.count))
        photoPool = pool
        if wasKept { keptCount = max(keptCount - 1, 0) }
        sessionSwipeCount = max(sessionSwipeCount - 1, 0)
        isSessionFinished = false
    }

    func onAllKeptPhotosReset() async {
        await loadPhotoPool()
        activeTab = .swipe
    }

    func setActiveTab(_ tab: SwipeTab) { activeTab = tab }

    func dismissMilestoneDialog() { showMilestoneDialog = false }

    private func advance() {
        currentIndex += 1
        sessionSwipeCount += 1
        showMilestoneDialog = sessionSwipeCount % Self.milestoneInterval == 0
        isSessionFinished = currentIndex >= photoPool.count
    }
}
