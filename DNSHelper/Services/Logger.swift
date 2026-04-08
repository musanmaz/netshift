import Foundation
import OSLog

final class AppLogger {
    static let shared = AppLogger()

    private let osLog = OSLog(subsystem: "com.musanmaz.netshift", category: "general")
    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.musanmaz.netshift.logger", qos: .utility)
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    private init() {
        let logsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs")
        logFileURL = logsDir.appendingPathComponent("DNS Helper.log")

        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
    }

    func debug(_ message: String) {
        log(level: .debug, message: message)
    }

    func info(_ message: String) {
        log(level: .info, message: message)
    }

    func warning(_ message: String) {
        log(level: .warning, message: message)
    }

    func error(_ message: String) {
        log(level: .error, message: message)
    }

    private func log(level: LogLevel, message: String) {
        let settingsLevel = AppSettings.shared.logLevel
        guard level.numericValue >= settingsLevel.numericValue else { return }

        let timestamp = dateFormatter.string(from: Date())
        let entry = "[\(timestamp)] [\(level.rawValue.uppercased())] \(message)\n"

        switch level {
        case .debug: os_log(.debug, log: osLog, "%{public}@", message)
        case .info: os_log(.info, log: osLog, "%{public}@", message)
        case .warning: os_log(.default, log: osLog, "%{public}@", message)
        case .error: os_log(.error, log: osLog, "%{public}@", message)
        }

        queue.async { [weak self] in
            guard let url = self?.logFileURL,
                  let data = entry.data(using: .utf8),
                  let handle = try? FileHandle(forWritingTo: url) else { return }
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        }
    }
}

private extension LogLevel {
    var numericValue: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }
}
