import Foundation
import OSLog

enum SendControlLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sendcontrol.app"
    private static let appLogger = Logger(subsystem: subsystem, category: "app")
    private static let eventTapLogger = Logger(subsystem: subsystem, category: "eventTap")

    static func appInfo(_ message: String) {
        appLogger.info("\(message, privacy: .public)")
    }

    static func appWarning(_ message: String) {
        appLogger.warning("\(message, privacy: .public)")
    }

    static func appError(_ message: String) {
        appLogger.error("\(message, privacy: .public)")
    }

    static func appDebug(_ message: String) {
#if DEBUG
        appLogger.debug("\(message, privacy: .public)")
#endif
    }

    static func eventTapInfo(_ message: String) {
        eventTapLogger.info("\(message, privacy: .public)")
    }

    static func eventTapWarning(_ message: String) {
        eventTapLogger.warning("\(message, privacy: .public)")
    }

    static func eventTapError(_ message: String) {
        eventTapLogger.error("\(message, privacy: .public)")
    }

    static func eventTapDebug(_ message: String) {
#if DEBUG
        eventTapLogger.debug("\(message, privacy: .public)")
#endif
    }
}
