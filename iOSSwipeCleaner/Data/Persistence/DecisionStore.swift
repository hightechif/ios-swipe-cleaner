import CoreData
import Foundation

/// Shared storage logic for the two identical decision tables (kept and trashed).
final class DecisionStore {
    struct Row: Equatable {
        let id: String
        let date: Date
    }

    private let entityName: String
    private let context: NSManagedObjectContext

    init(entityName: String, persistence: PersistenceController) {
        self.entityName = entityName
        self.context = persistence.newBackgroundContext()
    }

    func fetchAll() async -> [Row] {
        await context.perform { [entityName, context] in
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            let objects = (try? context.fetch(request)) ?? []
            return objects.compactMap { object in
                guard let id = object.value(forKey: "id") as? String,
                      let date = object.value(forKey: "date") as? Date else { return nil }
                return Row(id: id, date: date)
            }
        }
    }

    func upsert(id: String, date: Date) async throws {
        try await context.perform { [entityName, context] in
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            let object = try context.fetch(request).first
                ?? NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            object.setValue(id, forKey: "id")
            object.setValue(date, forKey: "date")
            try context.save()
        }
    }

    func delete(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        try await context.perform { [entityName, context] in
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = NSPredicate(format: "id IN %@", ids)
            try context.fetch(request).forEach(context.delete)
            try context.save()
        }
    }

    func clear() async throws {
        try await context.perform { [entityName, context] in
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            try context.fetch(request).forEach(context.delete)
            try context.save()
        }
    }
}
