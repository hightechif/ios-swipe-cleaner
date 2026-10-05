import Combine
import Foundation

protocol KeptPhotosRepositoryProtocol {
    func getKeptPhotos() async -> [KeptPhoto]
    var keptPhotosPublisher: AnyPublisher<[KeptPhoto], Never> { get }
    func insertKeptPhoto(id: String) async throws
    func deleteKeptPhoto(id: String) async throws
    func deleteKeptPhotos(ids: [String]) async throws
    func clearKeptPhotos() async throws
}
