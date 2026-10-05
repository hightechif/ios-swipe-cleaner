import os

enum AppLog {
    private static let subsystem = "com.hightechif.swipecleaner"
    static let swipe = Logger(subsystem: subsystem, category: "swipe")
    static let trash = Logger(subsystem: subsystem, category: "trash")
    static let kept = Logger(subsystem: subsystem, category: "kept")
}
