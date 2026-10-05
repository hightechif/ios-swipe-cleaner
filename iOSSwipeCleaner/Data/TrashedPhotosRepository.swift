import Combine
import Foundation

final class TrashedPhotosRepository: TrashedPhotosRepositoryProtocol {
    private let store: DecisionStore
    private let subject = CurrentValueSubject<[TrashedPhoto], Never>([])

    init(persistence: PersistenceController) {
        store = DecisionStore(entityName: "TrashedPhotoEntity", persistence: persistence)
        Task { await refresh() }
    }

    var trashedPhotosPublisher: AnyPublisher<[TrashedPhoto], Never> { subject.eraseToAnyPublisher() }

    func getTrashedPhotos() async -> [TrashedPhoto] { await store.fetchAll().map { TrashedPhoto(id: $0.id, trashedAt: $0.date) } }

    func insertTrashedPhoto(id: String) async throws {
        try await store.upsert(id: id, date: Date())
        await refresh()
    }

    func deleteTrashedPhoto(id: String) async throws { try await deleteTrashedPhotos(ids: [id]) }

    func deleteTrashedPhotos(ids: [String]) async throws {
        try await store.delete(ids: ids)
        await refresh()
    }

    func clearTrashedPhotos() async throws {
        try await store.clear()
        await refresh()
    }

    private func refresh() async { subject.send(await getTrashedPhotos()) }
}
