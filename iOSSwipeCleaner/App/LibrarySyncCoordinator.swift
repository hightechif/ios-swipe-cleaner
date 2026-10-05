import Combine
import Foundation

/// Keeps local decisions and the UI consistent with the photo library:
/// prunes records for deleted photos (full access only) and tells the deck to refresh.
@MainActor
final class LibrarySyncCoordinator {
    private var cancellables = Set<AnyCancellable>()
    private let currentAuthorization: () -> PhotoAuthorization
    private let pruneStaleDecisions: PruneStaleDecisionsUseCase
    private let onLibraryChanged: () async -> Void

    init(
        libraryChanges: AnyPublisher<Void, Never>,
        authorizationChanges: AnyPublisher<PhotoAuthorization, Never>,
        currentAuthorization: @escaping () -> PhotoAuthorization,
        pruneStaleDecisions: PruneStaleDecisionsUseCase,
        onLibraryChanged: @escaping () async -> Void,
        debounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)
    ) {
        self.currentAuthorization = currentAuthorization
        self.pruneStaleDecisions = pruneStaleDecisions
        self.onLibraryChanged = onLibraryChanged

        Publishers.Merge(libraryChanges, authorizationChanges.map { _ in () })
            .debounce(for: debounce, scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.sync() }
            .store(in: &cancellables)

        sync()  // once at launch
    }

    func sync() {
        Task { [currentAuthorization, pruneStaleDecisions, onLibraryChanged] in
            let authorization = currentAuthorization()
            await pruneStaleDecisions(authorization: authorization)
            if authorization.canReadLibrary { await onLibraryChanged() }
        }
    }
}
