import Combine
import XCTest
@testable import iOSSwipeCleaner

@MainActor
final class LibrarySyncCoordinatorTests: XCTestCase {
    private func makeSUT(
        authorization: PhotoAuthorization,
        library: FakePhotoLibrary,
        kept: FakeKeptPhotosRepository,
        onChanged: @escaping () async -> Void
    ) -> LibrarySyncCoordinator {
        LibrarySyncCoordinator(
            libraryChanges: library.changes,
            authorizationChanges: Empty().eraseToAnyPublisher(),
            currentAuthorization: { authorization },
            pruneStaleDecisions: PruneStaleDecisionsUseCase(
                photoLibrary: library, keptPhotos: kept, trashedPhotos: FakeTrashedPhotosRepository()),
            onLibraryChanged: onChanged,
            debounce: .milliseconds(10)
        )
    }

    func testLaunchSyncPrunesAndNotifiesWithFullAccess() async {
        let library = FakePhotoLibrary(images: makeImages([("alive", "x")]))
        let kept = FakeKeptPhotosRepository(ids: ["alive", "gone"])
        let notified = expectation(description: "notified")
        let sut = makeSUT(authorization: .full, library: library, kept: kept) { notified.fulfill() }
        await fulfillment(of: [notified], timeout: 2)
        let ids = await kept.getKeptPhotos().map(\.id)
        XCTAssertEqual(ids, ["alive"])
        _ = sut
    }

    func testLimitedAccessNotifiesButDoesNotPrune() async {
        let library = FakePhotoLibrary(images: makeImages([("alive", "x")]))
        let kept = FakeKeptPhotosRepository(ids: ["alive", "outside-selection"])
        let notified = expectation(description: "notified")
        let sut = makeSUT(authorization: .limited, library: library, kept: kept) { notified.fulfill() }
        await fulfillment(of: [notified], timeout: 2)
        let count = await kept.getKeptPhotos().count
        XCTAssertEqual(count, 2)
        _ = sut
    }

    func testNoAccessDoesNothing() async {
        let library = FakePhotoLibrary()
        let kept = FakeKeptPhotosRepository(ids: ["a"])
        let notified = expectation(description: "notified")
        notified.isInverted = true
        let sut = makeSUT(authorization: .denied, library: library, kept: kept) { notified.fulfill() }
        await fulfillment(of: [notified], timeout: 0.3)
        let count = await kept.getKeptPhotos().count
        XCTAssertEqual(count, 1)
        _ = sut
    }

    func testLibraryChangeTriggersAnotherSync() async {
        let library = FakePhotoLibrary()
        let kept = FakeKeptPhotosRepository()
        let notified = expectation(description: "notified twice")
        notified.expectedFulfillmentCount = 2
        let sut = makeSUT(authorization: .full, library: library, kept: kept) { notified.fulfill() }
        try? await Task.sleep(nanoseconds: 100_000_000)
        library.notifyChange()
        await fulfillment(of: [notified], timeout: 2)
        _ = sut
    }
}
