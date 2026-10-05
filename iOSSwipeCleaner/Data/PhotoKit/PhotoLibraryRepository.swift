import Combine
import Photos

final class PhotoLibraryRepository: NSObject, PhotoLibraryRepositoryProtocol, PHPhotoLibraryChangeObserver {
    private static let unknownAlbumName = "Unknown"

    /// Smart albums offered as filters. "All photos" is the unfiltered deck, so
    /// Recents / Library are deliberately not listed again.
    private static let smartAlbumSubtypes: [PHAssetCollectionSubtype] = [
        .smartAlbumFavorites, .smartAlbumScreenshots, .smartAlbumSelfPortraits,
        .smartAlbumPanoramas, .smartAlbumLivePhotos, .smartAlbumDepthEffect
    ]

    private let changeSubject = PassthroughSubject<Void, Never>()

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    var changes: AnyPublisher<Void, Never> { changeSubject.eraseToAnyPublisher() }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        changeSubject.send()
    }

    func fetchImageIds(albumId: String?) async -> [String] {
        let options = Self.imageOptions()
        let result: PHFetchResult<PHAsset>
        if let albumId {
            guard let collection = PHAssetCollection
                .fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil).firstObject
            else { return [] }
            result = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            result = PHAsset.fetchAssets(with: .image, options: options)
        }
        return Self.identifiers(of: result)
    }

    func fetchAllMediaImages() async -> [MediaImage] {
        var images: [MediaImage] = []
        for collection in Self.albumCollections() {
            let name = collection.localizedTitle ?? Self.unknownAlbumName
            let assets = PHAsset.fetchAssets(in: collection, options: Self.imageOptions())
            assets.enumerateObjects { asset, _, _ in
                images.append(MediaImage(id: asset.localIdentifier, albumId: collection.localIdentifier, albumName: name))
            }
        }
        return images
    }

    func existingIds(among ids: [String]) async -> Set<String> {
        guard !ids.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        return Set(Self.identifiers(of: result))
    }

    func deleteAssets(ids: [String]) async -> DeletionResult {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        // Photos that no longer resolve are gone or, with limited access, outside the user's selection.
        // They must not be reported as deleted, or their queue entries would be lost.
        guard assets.count > 0 else { return .notConfirmed }
        let resolvedIds = Self.identifiers(of: assets)
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets)
            }, completionHandler: { success, _ in
                continuation.resume(returning: success ? .confirmed(deletedIds: resolvedIds) : .notConfirmed)
            })
        }
    }

    // MARK: - Helpers

    private static func imageOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return options
    }

    private static func identifiers(of result: PHFetchResult<PHAsset>) -> [String] {
        var ids: [String] = []
        ids.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in ids.append(asset.localIdentifier) }
        return ids
    }

    private static func albumCollections() -> [PHAssetCollection] {
        var collections: [PHAssetCollection] = []
        PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            .enumerateObjects { collection, _, _ in collections.append(collection) }
        for subtype in smartAlbumSubtypes {
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
                .enumerateObjects { collection, _, _ in collections.append(collection) }
        }
        return collections
    }
}
