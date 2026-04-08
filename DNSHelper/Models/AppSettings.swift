import SwiftUI

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("showFileNameInStatusBar") var showFileNameInStatusBar = false
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("remoteSyncInterval") var remoteSyncInterval: RemoteSyncInterval = .sixHours
    @AppStorage("editorFontSize") var editorFontSize: Double = 13
    @AppStorage("showLineNumbers") var showLineNumbers = true
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") var appearanceMode: AppearanceMode = .system
    @AppStorage("logLevel") var logLevel: LogLevel = .info
    @AppStorage("helperInstalled") var helperInstalled = false

    private init() {}
}

enum RemoteSyncInterval: String, CaseIterable, Codable {
    case oneHour = "1h"
    case sixHours = "6h"
    case twentyFourHours = "24h"
    case manual = "manual"

    var label: String {
        switch self {
        case .oneHour: return "Every hour"
        case .sixHours: return "Every 6 hours"
        case .twentyFourHours: return "Daily"
        case .manual: return "Manual"
        }
    }

    var seconds: TimeInterval? {
        switch self {
        case .oneHour: return 3600
        case .sixHours: return 21600
        case .twentyFourHours: return 86400
        case .manual: return nil
        }
    }
}

enum AppearanceMode: String, CaseIterable, Codable {
    case system, light, dark

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum LogLevel: String, CaseIterable, Codable {
    case debug, info, warning, error

    var label: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}
