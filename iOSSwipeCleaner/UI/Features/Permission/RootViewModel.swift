import Combine
import Foundation

@MainActor
final class RootViewModel: ObservableObject {
    @Published private(set) var authorization: PhotoAuthorization

    private let authorizationService: PhotoAuthorizationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(authorizationService: PhotoAuthorizationServiceProtocol) {
        self.authorizationService = authorizationService
        self.authorization = authorizationService.status
        authorizationService.statusChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.authorization = $0 }
            .store(in: &cancellables)
    }

    func requestAccess() async {
        authorization = await authorizationService.requestAccess()
    }

    func openSettings() { authorizationService.openSettings() }

    func manageLimitedSelection() { authorizationService.presentLimitedLibraryPicker() }
}
