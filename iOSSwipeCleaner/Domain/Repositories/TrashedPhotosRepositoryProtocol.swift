import Combine
import Foundation

protocol TrashedPhotosRepositoryProtocol {
    func getTrashedPhotos() async -> [TrashedPhoto]
    var trashedPhotosPublisher: AnyPublisher<[TrashedPhoto], Never> { get }
    func insertTrashedPhoto(id: String) async throws
    func deleteTrashedPhoto(id: String) async throws
    func deleteTrashedPhotos(ids: [String]) async throws
    func clearTrashedPhotos() async throws
}
