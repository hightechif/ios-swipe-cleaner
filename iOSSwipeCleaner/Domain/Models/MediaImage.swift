import Foundation

/// One photo's membership of one album. A photo in several albums yields several values.
struct MediaImage: Equatable, Hashable {
    let id: String
    let albumId: String
    let albumName: String
}
