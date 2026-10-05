import Foundation

struct GetShuffledPhotoPoolUseCase {
    let photoLibrary: PhotoLibraryRepositoryProtocol
    let keptPhotos: KeptPhotosRepositoryProtocol
    let trashedPhotos: TrashedPhotosRepositoryProtocol
    var shuffler: ([String]) -> [String] = { $0.shuffled() }

    func callAsFunction(albumId: String?) async -> [String] {
        let all = await photoLibrary.fetchImageIds(albumId: albumId)
        let kept = Set(await keptPhotos.getKeptPhotos().map(\.id))
        let trashed = Set(await trashedPhotos.getTrashedPhotos().map(\.id))
        return shuffler(all.filter { !kept.contains($0) && !trashed.contains($0) })
    }
}

struct GetAllMediaImagesUseCase {
    let photoLibrary: PhotoLibraryRepositoryProtocol

    func callAsFunction() async -> [MediaImage] {
        await photoLibrary.fetchAllMediaImages()
    }
}

/// Albums that still contain unreviewed photos, with their unreviewed counts, sorted by name.
struct GetFilteredAlbumsUseCase {
    func callAsFunction(mediaImages: [MediaImage], keptIds: Set<String>, trashedIds: Set<String>) -> [Album] {
        var order: [String] = []
        var albums: [String: (name: String, cover: String, count: Int)] = [:]
        for image in mediaImages where !keptIds.contains(image.id) && !trashedIds.contains(image.id) {
            if var entry = albums[image.albumId] {
                entry.count += 1
                albums[image.albumId] = entry
            } else {
                order.append(image.albumId)
                albums[image.albumId] = (image.albumName, image.id, 1)
            }
        }
        return order
            .compactMap { id in albums[id].map { Album(id: id, name: $0.name, coverPhotoId: $0.cover, photoCount: $0.count) } }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

/// The subset of `ids` that still resolve to an accessible asset.
struct FindExistingPhotoIdsUseCase {
    let photoLibrary: PhotoLibraryRepositoryProtocol
    func callAsFunction(ids: [String]) async -> Set<String> { await photoLibrary.existingIds(among: ids) }
}
