import Combine
import Foundation

@MainActor
final class KeptPhotosViewModel: ObservableObject {
    @Published private(set) var keptPhotos: [KeptPhoto] = []
    @Published private(set) var mediaImages: [MediaImage] = []
    @Published private(set) var resolvedKeptPhotos: [ResolvedKeptPhoto] = []
    @Published private(set) var keptAlbums: [KeptAlbum] = []

    private let resetKeptPhotos: ResetKeptPhotosUseCase
    private let getAllMediaImages: GetAllMediaImagesUseCase
    private let restoreFromKept: RestoreFromKeptUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        getKeptPhotos: GetKeptPhotosUseCase,
        resetKeptPhotos: ResetKeptPhotosUseCase,
        getAllMediaImages: GetAllMediaImagesUseCase,
        restoreFromKept: RestoreFromKeptUseCase
    ) {
        self.resetKeptPhotos = resetKeptPhotos
        self.getAllMediaImages = getAllMediaImages
        self.restoreFromKept = restoreFromKept

        getKeptPhotos()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.keptPhotos = $0 }
            .store(in: &cancellables)

        Publishers.CombineLatest($keptPhotos, $mediaImages)
            .map { KeptPhotoMapper.resolve($0, mediaImages: $1) }
            .sink { [weak self] resolved in
                self?.resolvedKeptPhotos = resolved
                self?.keptAlbums = KeptPhotoMapper.albums(from: resolved)
            }
            .store(in: &cancellables)
    }

    /// Album membership is only needed for the Albums view, so it is loaded on demand.
    func refreshMediaImages() async {
        mediaImages = await getAllMediaImages()
    }

    /// Returns `true` when all kept records were cleared.
    func resetProgress() async -> Bool {
        do {
            try await resetKeptPhotos()
            return true
        } catch {
            AppLog.kept.error("Failed to reset kept photos: \(error.localizedDescription)")
            return false
        }
    }

    /// Returns `true` when the photo was removed from the kept list.
    func restoreKeptPhoto(id: String) async -> Bool {
        do {
            try await restoreFromKept(id: id)
            return true
        } catch {
            AppLog.kept.error("Failed to restore kept photo: \(error.localizedDescription)")
            return false
        }
    }
}
