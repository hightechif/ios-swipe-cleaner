import Combine
import XCTest
@testable import iOSSwipeCleaner

private final class FakeAuthorizationService: PhotoAuthorizationServiceProtocol {
    var status: PhotoAuthorization
    var requestResult: PhotoAuthorization = .full
    private(set) var openSettingsCount = 0
    private(set) var pickerCount = 0
    let subject = PassthroughSubject<PhotoAuthorization, Never>()

    init(status: PhotoAuthorization) { self.status = status }

    var statusChanges: AnyPublisher<PhotoAuthorization, Never> { subject.eraseToAnyPublisher() }
    func requestAccess() async -> PhotoAuthorization { requestResult }
    @MainActor func openSettings() { openSettingsCount += 1 }
    @MainActor func presentLimitedLibraryPicker() { pickerCount += 1 }
}

@MainActor
final class RootViewModelTests: XCTestCase {
    func testStartsWithCurrentStatus() {
        let sut = RootViewModel(authorizationService: FakeAuthorizationService(status: .denied))
        XCTAssertEqual(sut.authorization, .denied)
    }

    func testRequestAccessUpdatesAuthorization() async {
        let service = FakeAuthorizationService(status: .notDetermined)
        let sut = RootViewModel(authorizationService: service)
        await sut.requestAccess()
        XCTAssertEqual(sut.authorization, .full)
    }

    func testReactsToExternalStatusChange() {
        let service = FakeAuthorizationService(status: .denied)
        let sut = RootViewModel(authorizationService: service)
        let expectation = expectation(description: "updated")
        let cancellable = sut.$authorization.dropFirst().sink { _ in expectation.fulfill() }
        service.subject.send(.limited)
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(sut.authorization, .limited)
        cancellable.cancel()
    }

    func testCanReadLibrary() {
        XCTAssertTrue(PhotoAuthorization.full.canReadLibrary)
        XCTAssertTrue(PhotoAuthorization.limited.canReadLibrary)
        XCTAssertFalse(PhotoAuthorization.denied.canReadLibrary)
        XCTAssertFalse(PhotoAuthorization.notDetermined.canReadLibrary)
    }
}
