import Combine
import XCTest
@testable import iOSSwipeCleaner

private struct TestError: Error {}

@MainActor
final class SwipeViewModelTests: XCTestCase {
    private struct Harness {
        let sut: SwipeViewModel
        let library: FakePhotoLibrary
        let kept: FakeKeptPhotosRepository
        let trashed: FakeTrashedPhotosRepository
    }

    private func makeHarness(count: Int = 5, kept: [String] = [], trashed: [String] = []) -> Harness {
        let library = FakePhotoLibrary(images: makeImages((0..<count).map { ("p\($0)", "album") }))
        let keptRepo = FakeKeptPhotosRepository(ids: kept)
        let trashedRepo = FakeTrashedPhotosRepository(ids: trashed)
        let sut = SwipeViewModel(
            getShuffledPhotoPool: GetShuffledPhotoPoolUseCase(
                photoLibrary: library, keptPhotos: keptRepo, trashedPhotos: trashedRepo, shuffler: { $0 }),
            markImageKept: MarkImageKeptUseCase(keptPhotos: keptRepo),
            addToTrash: AddToTrashUseCase(trashedPhotos: trashedRepo),
            getAllMediaImages: GetAllMediaImagesUseCase(photoLibrary: library),
            findExistingPhotoIds: FindExistingPhotoIdsUseCase(photoLibrary: library),
            getFilteredAlbums: GetFilteredAlbumsUseCase(),
            getKeptPhotos: GetKeptPhotosUseCase(keptPhotos: keptRepo),
            getTrashedPhotos: GetTrashedPhotosUseCase(trashedPhotos: trashedRepo)
        )
        return Harness(sut: sut, library: library, kept: keptRepo, trashed: trashedRepo)
    }

    func testLoadPopulatesDeckWithoutReviewedPhotos() async {
        let h = makeHarness(count: 4, kept: ["p0"], trashed: ["p1"])
        await h.sut.loadPhotoPool()
        XCTAssertEqual(h.sut.photoPool, ["p2", "p3"])
        XCTAssertFalse(h.sut.isLoading)
        XCTAssertFalse(h.sut.isSessionFinished)
    }

    func testEmptyLibraryMarksSessionFinished() async {
        let h = makeHarness(count: 0)
        await h.sut.loadPhotoPool()
        XCTAssertTrue(h.sut.isSessionFinished)
    }

    func testSwipeLeftStagesPhotoAndAdvances() async {
        let h = makeHarness()
        await h.sut.loadPhotoPool()
        await h.sut.swipeLeft()
        let trashedIds = await h.trashed.getTrashedPhotos().map(\.id)
        let keptIds = await h.kept.getKeptPhotos().map(\.id)
        XCTAssertEqual(trashedIds, ["p0"])
        XCTAssertTrue(keptIds.isEmpty)
        XCTAssertEqual(h.sut.currentIndex, 1)
        XCTAssertEqual(h.sut.keptCount, 0)
    }

    func testSwipeRightKeepsPhotoAndCountsIt() async {
        let h = makeHarness()
        await h.sut.loadPhotoPool()
        await h.sut.swipeRight()
        let keptIds = await h.kept.getKeptPhotos().map(\.id)
        let trashedIds = await h.trashed.getTrashedPhotos().map(\.id)
        XCTAssertEqual(keptIds, ["p0"])
        XCTAssertTrue(trashedIds.isEmpty)
        XCTAssertEqual(h.sut.keptCount, 1)
        XCTAssertEqual(h.sut.currentIndex, 1)
    }

    func testLastSwipeFinishesSession() async {
        let h = makeHarness(count: 2)
        await h.sut.loadPhotoPool()
        await h.sut.swipeRight()
        XCTAssertFalse(h.sut.isSessionFinished)
        await h.sut.swipeLeft()
        XCTAssertTrue(h.sut.isSessionFinished)
    }

    func testSwipeWithEmptyDeckDoesNothing() async {
        let h = makeHarness(count: 0)
        await h.sut.loadPhotoPool()
        await h.sut.swipeLeft()
        await h.sut.swipeRight()
        XCTAssertEqual(h.sut.sessionSwipeCount, 0)
    }

    func testMilestoneAtFiftySwipes() async {
        let h = makeHarness(count: 60)
        await h.sut.loadPhotoPool()
        for _ in 0..<49 { await h.sut.swipeRight() }
        XCTAssertFalse(h.sut.showMilestoneDialog)
        await h.sut.swipeRight()
        XCTAssertTrue(h.sut.showMilestoneDialog)
        await h.sut.swipeRight()
        XCTAssertFalse(h.sut.showMilestoneDialog)
    }

    func testRestoredPhotoReentersDeckAtCurrentIndex() async {
        let h = makeHarness(count: 3)
        await h.sut.loadPhotoPool()
        await h.sut.swipeRight()
        h.sut.onPhotoRestored(id: "p0", wasKept: true)
        XCTAssertEqual(h.sut.photoPool, ["p0", "p0", "p1", "p2"])
        XCTAssertEqual(h.sut.currentIndex, 1)
        XCTAssertEqual(h.sut.currentPhotoId, "p0")
        XCTAssertEqual(h.sut.keptCount, 0)
        XCTAssertEqual(h.sut.sessionSwipeCount, 0)
        XCTAssertFalse(h.sut.isSessionFinished)
    }

    func testRestoreNeverDrivesCountersBelowZero() {
        let h = makeHarness()
        h.sut.onPhotoRestored(id: "x", wasKept: true)
        XCTAssertEqual(h.sut.keptCount, 0)
        XCTAssertEqual(h.sut.sessionSwipeCount, 0)
    }

    func testSelectAlbumReloadsDeckFromStart() async {
        let library = FakePhotoLibrary(images: makeImages([("a", "x"), ("b", "y"), ("c", "y")]))
        let keptRepo = FakeKeptPhotosRepository()
        let trashedRepo = FakeTrashedPhotosRepository()
        let sut = SwipeViewModel(
            getShuffledPhotoPool: GetShuffledPhotoPoolUseCase(
                photoLibrary: library, keptPhotos: keptRepo, trashedPhotos: trashedRepo, shuffler: { $0 }),
            markImageKept: MarkImageKeptUseCase(keptPhotos: keptRepo),
            addToTrash: AddToTrashUseCase(trashedPhotos: trashedRepo),
            getAllMediaImages: GetAllMediaImagesUseCase(photoLibrary: library),
            findExistingPhotoIds: FindExistingPhotoIdsUseCase(photoLibrary: library),
            getFilteredAlbums: GetFilteredAlbumsUseCase(),
            getKeptPhotos: GetKeptPhotosUseCase(keptPhotos: keptRepo),
            getTrashedPhotos: GetTrashedPhotosUseCase(trashedPhotos: trashedRepo)
        )
        await sut.loadPhotoPool()
        await sut.swipeRight()
        await sut.selectAlbum(Album(id: "y", name: "Y", coverPhotoId: "b", photoCount: 2))
        XCTAssertEqual(sut.photoPool, ["b", "c"])
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.sessionSwipeCount, 0)
    }

    func testAlbumsExcludeReviewedPhotosLive() async {
        let h = makeHarness(count: 2)
        await h.sut.loadPhotoPool()
        let populated = expectation(description: "albums populated")
        var bag = Set<AnyCancellable>()
        h.sut.$albums.filter { $0.first?.photoCount == 2 }.first().sink { _ in populated.fulfill() }.store(in: &bag)
        await fulfillment(of: [populated], timeout: 2)

        let reduced = expectation(description: "albums reduced")
        h.sut.$albums.filter { $0.first?.photoCount == 1 }.first().sink { _ in reduced.fulfill() }.store(in: &bag)
        await h.sut.swipeRight()
        await fulfillment(of: [reduced], timeout: 2)
    }

    func testLibraryChangeDropsDeletedPhotosFromRemainingDeck() async {
        let h = makeHarness(count: 4)
        await h.sut.loadPhotoPool()
        await h.sut.swipeRight()
        h.library.images.removeAll { $0.id == "p2" }
        await h.sut.refreshAfterLibraryChange()
        XCTAssertEqual(h.sut.photoPool, ["p0", "p1", "p3"])
        XCTAssertEqual(h.sut.currentIndex, 1)
        XCTAssertFalse(h.sut.isSessionFinished)
    }

    func testLibraryChangeFinishesSessionWhenRemainingPhotosAreGone() async {
        let h = makeHarness(count: 2)
        await h.sut.loadPhotoPool()
        await h.sut.swipeRight()
        h.library.images.removeAll { $0.id == "p1" }
        await h.sut.refreshAfterLibraryChange()
        XCTAssertTrue(h.sut.isSessionFinished)
    }

    func testLibraryChangeKeepsDeckWhenNothingMissing() async {
        let h = makeHarness(count: 3)
        await h.sut.loadPhotoPool()
        await h.sut.refreshAfterLibraryChange()
        XCTAssertEqual(h.sut.photoPool, ["p0", "p1", "p2"])
    }

    func testEmptyDeckReloadsWhenNewPhotosBecomeAvailable() async {
        let h = makeHarness(count: 0)
        await h.sut.loadPhotoPool()
        XCTAssertTrue(h.sut.photoPool.isEmpty)
        h.library.images = makeImages([("new1", "album"), ("new2", "album")])
        await h.sut.refreshAfterLibraryChange()
        XCTAssertEqual(Set(h.sut.photoPool), ["new1", "new2"])
        XCTAssertFalse(h.sut.isSessionFinished)
    }

    func testFinishedSessionIsNotResetByLibraryChange() async {
        let h = makeHarness(count: 1)
        await h.sut.loadPhotoPool()
        await h.sut.swipeRight()
        h.library.images.append(contentsOf: makeImages([("new", "album")]))
        await h.sut.refreshAfterLibraryChange()
        XCTAssertTrue(h.sut.isSessionFinished)
        XCTAssertEqual(h.sut.photoPool, ["p0"])
    }

    func testStartLoadsOnlyOnce() async {
        let h = makeHarness(count: 3)
        await h.sut.start()
        await h.sut.swipeRight()
        await h.sut.start()
        XCTAssertEqual(h.sut.currentIndex, 1)
    }
}

@MainActor
final class TrashViewModelTests: XCTestCase {
    /// `accessibleIds` are the photos the (fake) library can resolve; the rest behave like photos
    /// outside a limited selection. Defaults to every queued id.
    private func makeSUT(
        ids: [String],
        accessibleIds: [String]? = nil,
        userConfirms: Bool = true
    ) -> (TrashViewModel, FakePhotoLibrary, FakeTrashedPhotosRepository) {
        let library = FakePhotoLibrary(images: makeImages((accessibleIds ?? ids).map { ($0, "x") }))
        library.userConfirmsDeletion = userConfirms
        let trashed = FakeTrashedPhotosRepository(ids: ids)
        let sut = TrashViewModel(
            getTrashedPhotos: GetTrashedPhotosUseCase(trashedPhotos: trashed),
            deleteTrashedPhotos: DeleteTrashedPhotosUseCase(photoLibrary: library, trashedPhotos: trashed),
            removeTrashedPhotos: RemoveTrashedPhotosUseCase(trashedPhotos: trashed),
            restoreFromTrash: RestoreFromTrashUseCase(trashedPhotos: trashed)
        )
        return (sut, library, trashed)
    }

    func testQueueMirrorsStore() async {
        let (sut, _, _) = makeSUT(ids: ["a", "b"])
        await Task.yield()
        let populated = expectation(description: "queue")
        let c = sut.$deleteQueue.filter { $0.count == 2 }.first().sink { _ in populated.fulfill() }
        await fulfillment(of: [populated], timeout: 2)
        c.cancel()
        XCTAssertEqual(sut.deleteQueue, ["a", "b"])
    }

    func testConfirmedDeletionEmptiesQueue() async {
        let (sut, library, trashed) = makeSUT(ids: ["a", "b"])
        await waitForQueue(sut, count: 2)
        await sut.executeTrashRequest()
        XCTAssertEqual(library.deletedIds, ["a", "b"])
        let remaining = await trashed.getTrashedPhotos().count
        XCTAssertEqual(remaining, 0)
    }

    func testCancelledDeletionKeepsQueue() async {
        let (sut, library, trashed) = makeSUT(ids: ["a"], userConfirms: false)
        await waitForQueue(sut, count: 1)
        await sut.executeTrashRequest()
        XCTAssertEqual(library.deletedIds, ["a"])
        let remaining = await trashed.getTrashedPhotos().count
        XCTAssertEqual(remaining, 1)
    }

    func testPhotosOutsideLimitedSelectionStayQueued() async {
        let (sut, library, trashed) = makeSUT(ids: ["inside", "outside"], accessibleIds: ["inside"])
        await waitForQueue(sut, count: 2)
        await sut.executeTrashRequest()
        XCTAssertEqual(library.deletedIds, ["inside"])
        let remaining = await trashed.getTrashedPhotos().map(\.id)
        XCTAssertEqual(remaining, ["outside"])
    }

    func testNothingAccessibleLeavesQueueIntact() async {
        let (sut, _, trashed) = makeSUT(ids: ["outside"], accessibleIds: [])
        await waitForQueue(sut, count: 1)
        await sut.executeTrashRequest()
        let remaining = await trashed.getTrashedPhotos().map(\.id)
        XCTAssertEqual(remaining, ["outside"])
    }

    func testEmptyQueueDoesNotAskSystem() async {
        let (sut, library, _) = makeSUT(ids: [])
        await sut.executeTrashRequest()
        XCTAssertTrue(library.deletedIds.isEmpty)
    }

    func testRestoreRemovesFromQueue() async {
        let (sut, _, trashed) = makeSUT(ids: ["a", "b"])
        let ok = await sut.restoreFromTrash(id: "a")
        XCTAssertTrue(ok)
        let ids = await trashed.getTrashedPhotos().map(\.id)
        XCTAssertEqual(ids, ["b"])
    }

    private func waitForQueue(_ sut: TrashViewModel, count: Int) async {
        let populated = expectation(description: "queue \(count)")
        let c = sut.$deleteQueue.filter { $0.count == count }.first().sink { _ in populated.fulfill() }
        await fulfillment(of: [populated], timeout: 2)
        c.cancel()
    }
}

@MainActor
final class KeptPhotosViewModelTests: XCTestCase {
    private func makeSUT(kept: [String], images: [MediaImage]) -> (KeptPhotosViewModel, FakeKeptPhotosRepository) {
        let repo = FakeKeptPhotosRepository(ids: kept)
        let library = FakePhotoLibrary(images: images)
        let sut = KeptPhotosViewModel(
            getKeptPhotos: GetKeptPhotosUseCase(keptPhotos: repo),
            resetKeptPhotos: ResetKeptPhotosUseCase(keptPhotos: repo),
            getAllMediaImages: GetAllMediaImagesUseCase(photoLibrary: library),
            restoreFromKept: RestoreFromKeptUseCase(keptPhotos: repo)
        )
        return (sut, repo)
    }

    func testResolvesAndGroupsByAlbum() async {
        let (sut, _) = makeSUT(kept: ["a", "b", "c"], images: makeImages([("a", "trip"), ("b", "trip"), ("c", "family")]))
        await sut.refreshMediaImages()
        let ready = expectation(description: "albums")
        let cancellable = sut.$keptAlbums.filter { $0.count == 2 }.first().sink { _ in ready.fulfill() }
        await fulfillment(of: [ready], timeout: 2)
        cancellable.cancel()
        XCTAssertEqual(sut.keptAlbums.map(\.name), ["Family", "Trip"])
        XCTAssertEqual(sut.keptAlbums.last?.photoCount, 2)
    }

    func testResetClearsKept() async {
        let (sut, repo) = makeSUT(kept: ["a", "b"], images: [])
        let ok = await sut.resetProgress()
        XCTAssertTrue(ok)
        let remaining = await repo.getKeptPhotos().count
        XCTAssertEqual(remaining, 0)
    }

    func testRestoreSingleKeptPhoto() async {
        let (sut, repo) = makeSUT(kept: ["a", "b"], images: [])
        let ok = await sut.restoreKeptPhoto(id: "a")
        XCTAssertTrue(ok)
        let ids = await repo.getKeptPhotos().map(\.id)
        XCTAssertEqual(ids, ["b"])
    }
}

final class KeptPhotoMapperTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 0)

    func testUnknownPhotosGoToOthers() {
        let resolved = KeptPhotoMapper.resolve([KeptPhoto(id: "x", keptAt: date)], mediaImages: [])
        XCTAssertEqual(resolved.first?.albumId, KeptPhotoMapper.unknownAlbumId)
        XCTAssertEqual(resolved.first?.albumName, "Others")
    }

    func testPhotoInSeveralAlbumsUsesFirstMembership() {
        let images = [MediaImage(id: "a", albumId: "1", albumName: "First"), MediaImage(id: "a", albumId: "2", albumName: "Second")]
        let resolved = KeptPhotoMapper.resolve([KeptPhoto(id: "a", keptAt: date)], mediaImages: images)
        XCTAssertEqual(resolved.first?.albumName, "First")
    }

    func testAlbumsSortedByNameWithCoverAndCount() {
        let resolved = [
            ResolvedKeptPhoto(id: "1", keptAt: date, albumId: "z", albumName: "Zoo"),
            ResolvedKeptPhoto(id: "2", keptAt: date, albumId: "a", albumName: "Ant"),
            ResolvedKeptPhoto(id: "3", keptAt: date, albumId: "z", albumName: "Zoo")
        ]
        let albums = KeptPhotoMapper.albums(from: resolved)
        XCTAssertEqual(albums.map(\.name), ["Ant", "Zoo"])
        XCTAssertEqual(albums.last?.coverPhotoId, "1")
        XCTAssertEqual(albums.last?.photoCount, 2)
    }
}
