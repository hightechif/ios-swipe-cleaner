import Foundation

enum KeptPhotoMapper {
    static let unknownAlbumId = "unknown"
    static let unknownAlbumName = "Others"

    /// Attaches an album to each kept photo using its first album membership; unknown photos go to "Others".
    static func resolve(_ kept: [KeptPhoto], mediaImages: [MediaImage]) -> [ResolvedKeptPhoto] {
        var albumByPhoto: [String: MediaImage] = [:]
        for image in mediaImages where albumByPhoto[image.id] == nil {
            albumByPhoto[image.id] = image
        }
        return kept.map { photo in
            let media = albumByPhoto[photo.id]
            return ResolvedKeptPhoto(
                id: photo.id,
                keptAt: photo.keptAt,
                albumId: media?.albumId ?? unknownAlbumId,
                albumName: media?.albumName ?? unknownAlbumName
            )
        }
    }

    static func albums(from resolved: [ResolvedKeptPhoto]) -> [KeptAlbum] {
        var order: [String] = []
        var groups: [String: [ResolvedKeptPhoto]] = [:]
        for photo in resolved {
            if groups[photo.albumId] == nil { order.append(photo.albumId) }
            groups[photo.albumId, default: []].append(photo)
        }
        return order
            .compactMap { id -> KeptAlbum? in
                guard let photos = groups[id], let cover = photos.first else { return nil }
                return KeptAlbum(id: id, name: cover.albumName, coverPhotoId: cover.id, photoCount: photos.count, photos: photos)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
