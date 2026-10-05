import Foundation

struct ResolvedKeptPhoto: Equatable, Identifiable {
    let id: String
    let keptAt: Date
    let albumId: String
    let albumName: String
}

struct KeptAlbum: Equatable, Identifiable {
    let id: String
    let name: String
    let coverPhotoId: String
    let photoCount: Int
    let photos: [ResolvedKeptPhoto]
}

enum KeptViewMode: Equatable {
    case allPhotos, albums
}
