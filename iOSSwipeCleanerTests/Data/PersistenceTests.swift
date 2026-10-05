import Combine
import XCTest
@testable import iOSSwipeCleaner

final class KeptPhotosRepositoryTests: XCTestCase {
    private func makeSUT() -> KeptPhotosRepository {
        KeptPhotosRepository(persistence: PersistenceController(inMemory: true))
    }

    func testEmptyStoreReturnsEmptyList() async {
        let photos = await makeSUT().getKeptPhotos()
        XCTAssertTrue(photos.isEmpty)
    }

    func testInsertAndFetchKeepsFields() async throws {
        let sut = makeSUT()
        let before = Date()
        try await sut.insertKeptPhoto(id: "a")
        let photos = await sut.getKeptPhotos()
        XCTAssertEqual(photos.map(\.id), ["a"])
        XCTAssertGreaterThanOrEqual(photos[0].keptAt, before.addingTimeInterval(-1))
    }

    func testDuplicateInsertKeepsSingleRecord() async throws {
        let sut = makeSUT()
        try await sut.insertKeptPhoto(id: "a")
        try await sut.insertKeptPhoto(id: "a")
        let photos = await sut.getKeptPhotos()
        XCTAssertEqual(photos.count, 1)
    }

    func testDeleteById() async throws {
        let sut = makeSUT()
        try await sut.insertKeptPhoto(id: "a")
        try await sut.insertKeptPhoto(id: "b")
        try await sut.deleteKeptPhoto(id: "a")
        let ids = await sut.getKeptPhotos().map(\.id)
        XCTAssertEqual(ids, ["b"])
    }

    func testClearRemovesEverything() async throws {
        let sut = makeSUT()
        try await sut.insertKeptPhoto(id: "a")
        try await sut.insertKeptPhoto(id: "b")
        try await sut.clearKeptPhotos()
        let photos = await sut.getKeptPhotos()
        XCTAssertTrue(photos.isEmpty)
    }

    func testPublisherEmitsAfterInsert() async throws {
        let sut = makeSUT()
        var latest: [KeptPhoto] = []
        let cancellable = sut.keptPhotosPublisher.sink { latest = $0 }
        try await sut.insertKeptPhoto(id: "a")
        XCTAssertEqual(latest.map(\.id), ["a"])
        cancellable.cancel()
    }
}

final class TrashedPhotosRepositoryTests: XCTestCase {
    private func makeSUT() -> TrashedPhotosRepository {
        TrashedPhotosRepository(persistence: PersistenceController(inMemory: true))
    }

    func testInsertDeleteClear() async throws {
        let sut = makeSUT()
        try await sut.insertTrashedPhoto(id: "a")
        try await sut.insertTrashedPhoto(id: "b")
        var ids = await sut.getTrashedPhotos().map(\.id)
        XCTAssertEqual(ids, ["a", "b"])
        try await sut.deleteTrashedPhoto(id: "a")
        ids = await sut.getTrashedPhotos().map(\.id)
        XCTAssertEqual(ids, ["b"])
        try await sut.clearTrashedPhotos()
        let remaining = await sut.getTrashedPhotos()
        XCTAssertTrue(remaining.isEmpty)
    }

    func testKeptAndTrashedAreSeparateTables() async throws {
        let persistence = PersistenceController(inMemory: true)
        let kept = KeptPhotosRepository(persistence: persistence)
        let trashed = TrashedPhotosRepository(persistence: persistence)
        try await kept.insertKeptPhoto(id: "a")
        let trashedCount = await trashed.getTrashedPhotos().count
        XCTAssertEqual(trashedCount, 0)
    }
}
