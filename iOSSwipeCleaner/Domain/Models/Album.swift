import Foundation

struct Album: Equatable, Identifiable, Hashable {
    let id: String
    let name: String
    let coverPhotoId: String
    let photoCount: Int
}
