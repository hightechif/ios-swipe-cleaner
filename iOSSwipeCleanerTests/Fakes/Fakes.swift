import Combine
import Foundation
@testable import iOSSwipeCleaner

final class FakePhotoLibrary: PhotoLibraryRepositoryProtocol {
    var images: [MediaImage]
    /// Whether the (fake) user taps "Delete" in the system alert.
    var userConfirmsDeletion = true
    private(set) var deletedIds: [String] = []
    private let changeSubject = PassthroughSubject<Void, Never>()

    init(images: [MediaImage] = []) { self.images = images }

    var changes: AnyPublisher<Void, Never> { changeSubject.eraseToAnyPublisher() }
    func notifyChange() { changeSubject.send() }

    func fetchImageIds(albumId: String?) async -> [String] {
        var seen = Set<String>()
        return images
            .filter { albumId == nil || $0.albumId == albumId }
            .map(\.id)
            .filter { seen.insert($0).inserted }
    }

    func fetchAllMediaImages() async -> [MediaImage] { images }

    func existingIds(among ids: [String]) async -> Set<String> {
        let known = Set(images.map(\.id))
        return Set(ids.filter(known.contains))
    }

    func deleteAssets(ids: [String]) async -> DeletionResult {
        let accessible = Set(images.map(\.id))
        let resolvable = ids.filter(accessible.contains)
        guard !resolvable.isEmpty else { return .notConfirmed }
        deletedIds = resolvable
        guard userConfirmsDeletion else { return .notConfirmed }
        images.removeAll { resolvable.contains($0.id) }
        return .confirmed(deletedIds: resolvable)
    }
}

final class FakeKeptPhotosRepository: KeptPhotosRepositoryProtocol {
    private let subject: CurrentValueSubject<[KeptPhoto], Never>
    var insertError: Error?

    init(ids: [String] = []) {
        subject = CurrentValueSubject(ids.map { KeptPhoto(id: $0, keptAt: Date(timeIntervalSince1970: 0)) })
    }

    var keptPhotosPublisher: AnyPublisher<[KeptPhoto], Never> { subject.eraseToAnyPublisher() }
    func getKeptPhotos() async -> [KeptPhoto] { subject.value }
    func insertKeptPhoto(id: String) async throws {
        if let insertError { throw insertError }
        guard !subject.value.contains(where: { $0.id == id }) else { return }
        subject.value.append(KeptPhoto(id: id, keptAt: Date()))
    }
    func deleteKeptPhoto(id: String) async throws { subject.value.removeAll { $0.id == id } }
    func deleteKeptPhotos(ids: [String]) async throws { subject.value.removeAll { ids.contains($0.id) } }
    func clearKeptPhotos() async throws { subject.value = [] }
}

final class FakeTrashedPhotosRepository: TrashedPhotosRepositoryProtocol {
    private let subject: CurrentValueSubject<[TrashedPhoto], Never>
    var insertError: Error?

    init(ids: [String] = []) {
        subject = CurrentValueSubject(ids.map { TrashedPhoto(id: $0, trashedAt: Date(timeIntervalSince1970: 0)) })
    }

    var trashedPhotosPublisher: AnyPublisher<[TrashedPhoto], Never> { subject.eraseToAnyPublisher() }
    func getTrashedPhotos() async -> [TrashedPhoto] { subject.value }
    func insertTrashedPhoto(id: String) async throws {
        if let insertError { throw insertError }
        guard !subject.value.contains(where: { $0.id == id }) else { return }
        subject.value.append(TrashedPhoto(id: id, trashedAt: Date()))
    }
    func deleteTrashedPhoto(id: String) async throws { subject.value.removeAll { $0.id == id } }
    func deleteTrashedPhotos(ids: [String]) async throws { subject.value.removeAll { ids.contains($0.id) } }
    func clearTrashedPhotos() async throws { subject.value = [] }
}

func makeImages(_ spec: [(id: String, album: String)]) -> [MediaImage] {
    spec.map { MediaImage(id: $0.id, albumId: $0.album, albumName: $0.album.capitalized) }
}
