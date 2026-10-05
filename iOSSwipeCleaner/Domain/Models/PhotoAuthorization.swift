import Foundation

enum PhotoAuthorization: Equatable {
    case notDetermined
    /// Denied by the user or restricted by the system.
    case denied
    /// The user shared a selection of photos only.
    case limited
    case full

    var canReadLibrary: Bool { self == .limited || self == .full }
}

enum DeletionResult: Equatable {
    /// The user confirmed; `deletedIds` are the photos that were actually removed from the library.
    case confirmed(deletedIds: [String])
    /// The user cancelled, the request failed, or none of the photos could be accessed.
    case notConfirmed
}
