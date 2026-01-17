import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let app = Logger(subsystem: subsystem, category: "App")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let ai = Logger(subsystem: subsystem, category: "AI")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let service = Logger(subsystem: subsystem, category: "Service")
    static let export = Logger(subsystem: subsystem, category: "Export")
    static let import_ = Logger(subsystem: subsystem, category: "Import")
    static let backup = Logger(subsystem: subsystem, category: "Backup")
    static let privacy = Logger(subsystem: subsystem, category: "Privacy")
    static let audit = Logger(subsystem: subsystem, category: "Audit")
}
