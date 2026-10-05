import XCTest
@testable import iOSSwipeCleaner

final class GetShuffledPhotoPoolTests: XCTestCase {
    private func makeSUT(kept: [String] = [], trashed: [String] = [], library: FakePhotoLibrary) -> GetShuffledPhotoPoolUseCase {
        GetShuffledPhotoPoolUseCase(
            photoLibrary: library,
            keptPhotos: FakeKeptPhotosRepository(ids: kept),
            trashedPhotos: FakeTrashedPhotosRepository(ids: trashed),
            shuffler: { $0 }
        )
    }

    func testExcludesKeptAndTrashed() async {
        let library = FakePhotoLibrary(images: makeImages([("a", "x"), ("b", "x"), ("c", "x"), ("d", "x")]))
        let sut = makeSUT(kept: ["a"], trashed: ["c"], library: library)
        let pool = await sut(albumId: nil)
        XCTAssertEqual(pool, ["b", "d"])
    }

    func testEmptyWhenEverythingReviewed() async {
        let library = FakePhotoLibrary(images: makeImages([("a", "x"), ("b", "x")]))
        let sut = makeSUT(kept: ["a"], trashed: ["b"], library: library)
        let pool = await sut(albumId: nil)
        XCTAssertTrue(pool.isEmpty)
    }

    func testRestrictsToAlbum() async {
        let library = FakePhotoLibrary(images: makeImages([("a", "x"), ("b", "y"), ("c", "y")]))
        let sut = makeSUT(kept: ["c"], library: library)
        let pool = await sut(albumId: "y")
        XCTAssertEqual(pool, ["b"])
    }

    func testPhotoInTwoAlbumsAppearsOnceInAllPhotos() async {
        let library = FakePhotoLibrary(images: makeImages([("a", "x"), ("a", "y")]))
        let sut = makeSUT(library: library)
        let pool = await sut(albumId: nil)
        XCTAssertEqual(pool, ["a"])
    }

    func testUsesInjectedShuffler() async {
        let library = FakePhotoLibrary(images: makeImages([("a", "x"), ("b", "x"), ("c", "x")]))
        let sut = GetShuffledPhotoPoolUseCase(
            photoLibrary: library,
            keptPhotos: FakeKeptPhotosRepository(),
            trashedPhotos: FakeTrashedPhotosRepository(),
            shuffler: { $0.reversed() }
        )
        let pool = await sut(albumId: nil)
        XCTAssertEqual(pool, ["c", "b", "a"])
    }
}

final class GetFilteredAlbumsTests: XCTestCase {
    private let sut = GetFilteredAlbumsUseCase()

    func testCountsUnreviewedPerAlbumAndSortsByName() {
        let images = makeImages([("1", "trip"), ("2", "trip"), ("3", "family"), ("4", "trip")])
        let albums = sut(mediaImages: images, keptIds: ["1"], trashedIds: ["3"])
        XCTAssertEqual(albums.map(\.name), ["Trip"])
        XCTAssertEqual(albums.first?.photoCount, 2)
    }

    func testOmitsFullyReviewedAlbums() {
        let images = makeImages([("1", "a"), ("2", "b")])
        let albums = sut(mediaImages: images, keptIds: ["1"], trashedIds: [])
        XCTAssertEqual(albums.map(\.id), ["b"])
    }

    func testPhotoInTwoAlbumsCountsInBoth() {
        let images = makeImages([("1", "a"), ("1", "b")])
        let albums = sut(mediaImages: images, keptIds: [], trashedIds: [])
        XCTAssertEqual(albums.map(\.photoCount), [1, 1])
    }

    func testCoverIsFirstUnreviewedPhoto() {
        let images = makeImages([("1", "a"), ("2", "a")])
        let albums = sut(mediaImages: images, keptIds: ["1"], trashedIds: [])
        XCTAssertEqual(albums.first?.coverPhotoId, "2")
    }
}

final class DecisionUseCaseTests: XCTestCase {
    func testMarkKeptAndRestore() async throws {
        let kept = FakeKeptPhotosRepository()
        try await MarkImageKeptUseCase(keptPhotos: kept)(id: "a")
        var ids = await kept.getKeptPhotos().map(\.id)
        XCTAssertEqual(ids, ["a"])
        try await RestoreFromKeptUseCase(keptPhotos: kept)(id: "a")
        ids = await kept.getKeptPhotos().map(\.id)
        XCTAssertTrue(ids.isEmpty)
    }

    func testAddToTrashAndRestore() async throws {
        let trashed = FakeTrashedPhotosRepository()
        try await AddToTrashUseCase(trashedPhotos: trashed)(id: "a")
        var ids = await trashed.getTrashedPhotos().map(\.id)
        XCTAssertEqual(ids, ["a"])
        try await RestoreFromTrashUseCase(trashedPhotos: trashed)(id: "a")
        ids = await trashed.getTrashedPhotos().map(\.id)
        XCTAssertTrue(ids.isEmpty)
    }

    func testDeleteTrashedPassesQueueToLibraryAndLeavesQueueUntouched() async {
        let library = FakePhotoLibrary(images: makeImages([("a", "x"), ("b", "x")]))
        let trashed = FakeTrashedPhotosRepository(ids: ["a", "b"])
        let result = await DeleteTrashedPhotosUseCase(photoLibrary: library, trashedPhotos: trashed)()
        XCTAssertEqual(result, .confirmed(deletedIds: ["a", "b"]))
        XCTAssertEqual(library.deletedIds, ["a", "b"])
        let queued = await trashed.getTrashedPhotos().map(\.id)
        XCTAssertEqual(queued, ["a", "b"])
    }

    func testDeleteReportsOnlyPhotosTheLibraryCouldResolve() async {
        // "outside" simulates a photo outside the user's limited selection.
        let library = FakePhotoLibrary(images: makeImages([("inside", "x")]))
        let trashed = FakeTrashedPhotosRepository(ids: ["inside", "outside"])
        let result = await DeleteTrashedPhotosUseCase(photoLibrary: library, trashedPhotos: trashed)()
        XCTAssertEqual(result, .confirmed(deletedIds: ["inside"]))
    }

    func testDeleteWithNothingAccessibleIsNotConfirmed() async {
        let library = FakePhotoLibrary(images: [])
        let trashed = FakeTrashedPhotosRepository(ids: ["outside"])
        let result = await DeleteTrashedPhotosUseCase(photoLibrary: library, trashedPhotos: trashed)()
        XCTAssertEqual(result, .notConfirmed)
    }

    func testDeleteWithEmptyQueueSkipsSystemRequest() async {
        let library = FakePhotoLibrary()
        let result = await DeleteTrashedPhotosUseCase(photoLibrary: library, trashedPhotos: FakeTrashedPhotosRepository())()
        XCTAssertEqual(result, .notConfirmed)
        XCTAssertTrue(library.deletedIds.isEmpty)
    }

    func testDeleteReportsCancellation() async {
        let library = FakePhotoLibrary(images: makeImages([("a", "x")]))
        library.userConfirmsDeletion = false
        let result = await DeleteTrashedPhotosUseCase(photoLibrary: library, trashedPhotos: FakeTrashedPhotosRepository(ids: ["a"]))()
        XCTAssertEqual(result, .notConfirmed)
    }
}

final class PruneStaleDecisionsTests: XCTestCase {
    private func makeSUT() -> (PruneStaleDecisionsUseCase, FakeKeptPhotosRepository, FakeTrashedPhotosRepository) {
        let library = FakePhotoLibrary(images: makeImages([("keep-alive", "x"), ("trash-alive", "x")]))
        let kept = FakeKeptPhotosRepository(ids: ["keep-alive", "keep-gone"])
        let trashed = FakeTrashedPhotosRepository(ids: ["trash-alive", "trash-gone"])
        return (PruneStaleDecisionsUseCase(photoLibrary: library, keptPhotos: kept, trashedPhotos: trashed), kept, trashed)
    }

    func testFullAccessRemovesMissingAssets() async {
        let (sut, kept, trashed) = makeSUT()
        await sut(authorization: .full)
        let keptIds = await kept.getKeptPhotos().map(\.id)
        let trashedIds = await trashed.getTrashedPhotos().map(\.id)
        XCTAssertEqual(keptIds, ["keep-alive"])
        XCTAssertEqual(trashedIds, ["trash-alive"])
    }

    func testLimitedAccessDoesNotPrune() async {
        let (sut, kept, trashed) = makeSUT()
        await sut(authorization: .limited)
        let keptCount = await kept.getKeptPhotos().count
        let trashedCount = await trashed.getTrashedPhotos().count
        XCTAssertEqual(keptCount, 2)
        XCTAssertEqual(trashedCount, 2)
    }
}
