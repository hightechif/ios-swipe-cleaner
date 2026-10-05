import Combine
import Foundation

struct MarkImageKeptUseCase {
    let keptPhotos: KeptPhotosRepositoryProtocol
    func callAsFunction(id: String) async throws { try await keptPhotos.insertKeptPhoto(id: id) }
}

struct AddToTrashUseCase {
    let trashedPhotos: TrashedPhotosRepositoryProtocol
    func callAsFunction(id: String) async throws { try await trashedPhotos.insertTrashedPhoto(id: id) }
}

struct GetKeptPhotosUseCase {
    let keptPhotos: KeptPhotosRepositoryProtocol
    func callAsFunction() -> AnyPublisher<[KeptPhoto], Never> { keptPhotos.keptPhotosPublisher }
}

struct GetTrashedPhotosUseCase {
    let trashedPhotos: TrashedPhotosRepositoryProtocol
    func callAsFunction() -> AnyPublisher<[TrashedPhoto], Never> { trashedPhotos.trashedPhotosPublisher }
}

struct RestoreFromKeptUseCase {
    let keptPhotos: KeptPhotosRepositoryProtocol
    func callAsFunction(id: String) async throws { try await keptPhotos.deleteKeptPhoto(id: id) }
}

struct RestoreFromTrashUseCase {
    let trashedPhotos: TrashedPhotosRepositoryProtocol
    func callAsFunction(id: String) async throws { try await trashedPhotos.deleteTrashedPhoto(id: id) }
}

struct ResetKeptPhotosUseCase {
    let keptPhotos: KeptPhotosRepositoryProtocol
    func callAsFunction() async throws { try await keptPhotos.clearKeptPhotos() }
}

/// Removes photos from the local queue once the library confirms they were deleted.
struct RemoveTrashedPhotosUseCase {
    let trashedPhotos: TrashedPhotosRepositoryProtocol
    func callAsFunction(ids: [String]) async throws { try await trashedPhotos.deleteTrashedPhotos(ids: ids) }
}

/// Asks the system to delete the queued photos. Does not touch the local queue;
/// the caller removes only the photos reported in `.confirmed(deletedIds:)`.
struct DeleteTrashedPhotosUseCase {
    let photoLibrary: PhotoLibraryRepositoryProtocol
    let trashedPhotos: TrashedPhotosRepositoryProtocol

    func callAsFunction() async -> DeletionResult {
        let ids = await trashedPhotos.getTrashedPhotos().map(\.id)
        guard !ids.isEmpty else { return .notConfirmed }
        return await photoLibrary.deleteAssets(ids: ids)
    }
}

/// Removes kept/trashed records whose assets no longer exist. Skipped unless access is full,
/// because with limited access unresolved identifiers may belong to photos outside the selection.
struct PruneStaleDecisionsUseCase {
    let photoLibrary: PhotoLibraryRepositoryProtocol
    let keptPhotos: KeptPhotosRepositoryProtocol
    let trashedPhotos: TrashedPhotosRepositoryProtocol

    func callAsFunction(authorization: PhotoAuthorization) async {
        guard authorization == .full else { return }
        let kept = await keptPhotos.getKeptPhotos().map(\.id)
        let trashed = await trashedPhotos.getTrashedPhotos().map(\.id)
        let existing = await photoLibrary.existingIds(among: kept + trashed)
        let staleKept = kept.filter { !existing.contains($0) }
        let staleTrashed = trashed.filter { !existing.contains($0) }
        if !staleKept.isEmpty { try? await keptPhotos.deleteKeptPhotos(ids: staleKept) }
        if !staleTrashed.isEmpty { try? await trashedPhotos.deleteTrashedPhotos(ids: staleTrashed) }
    }
}
