import os

/// Loggers, grouped by area. View them with:
///   log stream --predicate 'subsystem == "studio.g6.divgrid"'
enum Log {
    private static let subsystem = "studio.g6.divgrid"

    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    static let window = Logger(subsystem: subsystem, category: "window")
    static let hotKey = Logger(subsystem: subsystem, category: "hotkey")
    static let grid = Logger(subsystem: subsystem, category: "grid")
}
