import Combine
import Foundation

@MainActor
final class TrashViewModel: ObservableObject {
    @Published private(set) var deleteQueue: [String] = []

    private let deleteTrashedPhotos: DeleteTrashedPhotosUseCase
    private let removeTrashedPhotos: RemoveTrashedPhotosUseCase
    private let restoreFromTrash: RestoreFromTrashUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        getTrashedPhotos: GetTrashedPhotosUseCase,
        deleteTrashedPhotos: DeleteTrashedPhotosUseCase,
        removeTrashedPhotos: RemoveTrashedPhotosUseCase,
        restoreFromTrash: RestoreFromTrashUseCase
    ) {
        self.deleteTrashedPhotos = deleteTrashedPhotos
        self.removeTrashedPhotos = removeTrashedPhotos
        self.restoreFromTrash = restoreFromTrash
        getTrashedPhotos()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.deleteQueue = $0.map(\.id) }
            .store(in: &cancellables)
    }

    /// Asks the system to delete the queued photos. Only photos the library confirms as deleted leave the queue.
    func executeTrashRequest() async {
        guard !deleteQueue.isEmpty else { return }
        let result = await deleteTrashedPhotos()
        guard case .confirmed(let deletedIds) = result else { return }
        do {
            try await removeTrashedPhotos(ids: deletedIds)
        } catch {
            AppLog.trash.error("Failed to update trash queue: \(error.localizedDescription)")
        }
    }

    /// Returns `true` when the photo was removed from the queue.
    func restoreFromTrash(id: String) async -> Bool {
        do {
            try await restoreFromTrash(id: id)
            return true
        } catch {
            AppLog.trash.error("Failed to restore from trash: \(error.localizedDescription)")
            return false
        }
    }
}
