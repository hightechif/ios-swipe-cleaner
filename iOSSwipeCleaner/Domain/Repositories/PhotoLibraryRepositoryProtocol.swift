import Combine
import Foundation

protocol PhotoLibraryRepositoryProtocol {
    /// Identifiers of all accessible images, optionally restricted to one album, newest first.
    func fetchImageIds(albumId: String?) async -> [String]
    /// Every (photo, album) membership for accessible images.
    func fetchAllMediaImages() async -> [MediaImage]
    /// The subset of `ids` that still resolve to an asset.
    func existingIds(among ids: [String]) async -> Set<String>
    /// Deletes the assets in one request that shows the system confirmation alert.
    func deleteAssets(ids: [String]) async -> DeletionResult
    /// Emits whenever the photo library changes.
    var changes: AnyPublisher<Void, Never> { get }
}

protocol PhotoAuthorizationServiceProtocol {
    var status: PhotoAuthorization { get }
    func requestAccess() async -> PhotoAuthorization
    @MainActor func openSettings()
    @MainActor func presentLimitedLibraryPicker()
    var statusChanges: AnyPublisher<PhotoAuthorization, Never> { get }
}
