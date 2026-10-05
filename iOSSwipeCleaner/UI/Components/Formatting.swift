import Foundation

enum Formatting {
    /// "1 photo" / "3 photos".
    static func photos(_ count: Int) -> String { count == 1 ? "1 photo" : "\(count) photos" }
    /// "Delete 1 Photo" / "Delete 3 Photos".
    static func deleteButtonTitle(_ count: Int) -> String { count == 1 ? "Delete 1 Photo" : "Delete \(count) Photos" }
}
