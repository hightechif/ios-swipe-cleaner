import Combine
import Foundation

final class KeptPhotosRepository: KeptPhotosRepositoryProtocol {
    private let store: DecisionStore
    private let subject = CurrentValueSubject<[KeptPhoto], Never>([])

    init(persistence: PersistenceController) {
        store = DecisionStore(entityName: "KeptPhotoEntity", persistence: persistence)
        Task { await refresh() }
    }

    var keptPhotosPublisher: AnyPublisher<[KeptPhoto], Never> { subject.eraseToAnyPublisher() }

    func getKeptPhotos() async -> [KeptPhoto] { await store.fetchAll().map { KeptPhoto(id: $0.id, keptAt: $0.date) } }

    func insertKeptPhoto(id: String) async throws {
        try await store.upsert(id: id, date: Date())
        await refresh()
    }

    func deleteKeptPhoto(id: String) async throws { try await deleteKeptPhotos(ids: [id]) }

    func deleteKeptPhotos(ids: [String]) async throws {
        try await store.delete(ids: ids)
        await refresh()
    }

    func clearKeptPhotos() async throws {
        try await store.clear()
        await refresh()
    }

    private func refresh() async { subject.send(await getKeptPhotos()) }
}
