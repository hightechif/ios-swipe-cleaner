import Combine
import Photos
import PhotosUI
import UIKit

final class PhotoAuthorizationService: PhotoAuthorizationServiceProtocol {
    private let subject = PassthroughSubject<PhotoAuthorization, Never>()

    var status: PhotoAuthorization { Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite)) }

    /// Emits on explicit requests and whenever the app returns to the foreground
    /// (the user may have changed access in Settings).
    var statusChanges: AnyPublisher<PhotoAuthorization, Never> {
        let foreground = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { [weak self] _ in self?.status ?? .notDetermined }
        return subject.merge(with: foreground)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func requestAccess() async -> PhotoAuthorization {
        let result: PhotoAuthorization = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { continuation.resume(returning: Self.map($0)) }
        }
        subject.send(result)
        return result
    }

    @MainActor
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @MainActor
    func presentLimitedLibraryPicker() {
        guard let controller = Self.topViewController() else { return }
        // presentLimitedLibraryPicker is an Objective-C category method in PhotosUI. No Swift symbol from
        // PhotosUI is referenced, so the framework is linked explicitly via OTHER_LDFLAGS in the project;
        // without that the selector is missing at runtime and the app crashes.
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
    }

    private static func map(_ status: PHAuthorizationStatus) -> PhotoAuthorization {
        switch status {
        case .authorized: return .full
        case .limited: return .limited
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var controller = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }
}
