import CoreData
import Foundation

/// Owns the Core Data stack. Use `inMemory: true` in tests.
final class PersistenceController {
    static let modelName = "SwipeCleaner"

    /// Shared so several controllers (e.g. in tests) never register the same entity classes twice.
    private static let model: NSManagedObjectModel = {
        guard
            let url = Bundle(for: AppBundleToken.self).url(forResource: modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: url)
        else { fatalError("Missing Core Data model \(modelName)") }
        return model
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: Self.modelName, managedObjectModel: Self.model)
        let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        if inMemory {
            description.type = NSInMemoryStoreType
            description.url = nil
        }
        // Lightweight migration so later schema changes keep the user's progress.
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data failed to load: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
