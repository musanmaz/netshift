import SwiftUI
import AppKit

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var showFileNameInStatusBar: Bool {
        didSet { UserDefaults.standard.set(showFileNameInStatusBar, forKey: "showFileNameInStatusBar") }
    }
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    @Published var remoteSyncInterval: RemoteSyncInterval {
        didSet { UserDefaults.standard.set(remoteSyncInterval.rawValue, forKey: "remoteSyncInterval") }
    }
    @Published var editorFontSize: Double {
        didSet { UserDefaults.standard.set(editorFontSize, forKey: "editorFontSize") }
    }
    @Published var showLineNumbers: Bool {
        didSet { UserDefaults.standard.set(showLineNumbers, forKey: "showLineNumbers") }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
            applyAppearance()
        }
    }
    @Published var logLevel: LogLevel {
        didSet { UserDefaults.standard.set(logLevel.rawValue, forKey: "logLevel") }
    }
    @Published var helperInstalled: Bool {
        didSet { UserDefaults.standard.set(helperInstalled, forKey: "helperInstalled") }
    }

    private init() {
        let defaults = UserDefaults.standard
        self.showFileNameInStatusBar = defaults.bool(forKey: "showFileNameInStatusBar")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        self.helperInstalled = defaults.bool(forKey: "helperInstalled")

        let fontSize = defaults.double(forKey: "editorFontSize")
        self.editorFontSize = fontSize > 0 ? fontSize : 13

        self.showLineNumbers = defaults.object(forKey: "showLineNumbers") == nil
            ? true : defaults.bool(forKey: "showLineNumbers")

        if let raw = defaults.string(forKey: "remoteSyncInterval"),
           let val = RemoteSyncInterval(rawValue: raw) {
            self.remoteSyncInterval = val
        } else {
            self.remoteSyncInterval = .sixHours
        }

        if let raw = defaults.string(forKey: "appearanceMode"),
           let val = AppearanceMode(rawValue: raw) {
            self.appearanceMode = val
        } else {
            self.appearanceMode = .system
        }

        if let raw = defaults.string(forKey: "logLevel"),
           let val = LogLevel(rawValue: raw) {
            self.logLevel = val
        } else {
            self.logLevel = .info
        }

        applyAppearance()
    }

    func applyAppearance() {
        DispatchQueue.main.async {
            switch self.appearanceMode {
            case .system:
                NSApp?.appearance = nil
            case .light:
                NSApp?.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp?.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
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

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
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
