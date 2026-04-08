import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            GeneralPrefsTab()
                .tabItem { Label("General", systemImage: "gearshape") }
            AppearancePrefsTab()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            SyncPrefsTab()
                .tabItem { Label("Sync", systemImage: "arrow.triangle.2.circlepath") }
            AdvancedPrefsTab()
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .frame(
            width: DesignTokens.WindowSize.preferences.width,
            height: DesignTokens.WindowSize.preferences.height
        )
        .environmentObject(settings)
    }
}

// MARK: - General

struct GeneralPrefsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle("Show file name in menu bar", isOn: $settings.showFileNameInStatusBar)
            }

            Section("Notifications") {
                Text("Send notifications on DNS or hosts changes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(DesignTokens.Spacing.lg)
    }
}

// MARK: - Appearance

struct AppearancePrefsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Appearance", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Editor") {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(settings.editorFontSize)) pt")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.editorFontSize, in: 10...24, step: 1)

                Toggle("Show line numbers", isOn: $settings.showLineNumbers)
            }
        }
        .formStyle(.grouped)
        .padding(DesignTokens.Spacing.lg)
    }
}

// MARK: - Sync

struct SyncPrefsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Remote File Updates") {
                Picker("Update frequency", selection: $settings.remoteSyncInterval) {
                    ForEach(RemoteSyncInterval.allCases, id: \.self) { interval in
                        Text(interval.label).tag(interval)
                    }
                }
            }

            Section {
                Button("Sync All Remote Files Now") {
                    Task { await RemoteSyncService.shared.syncAllRemoteFiles() }
                }

                if let lastSync = RemoteSyncService.shared.lastSyncDate {
                    HStack {
                        Text("Last sync:")
                            .foregroundStyle(.secondary)
                        Text(lastSync, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding(DesignTokens.Spacing.lg)
    }
}

// MARK: - Advanced

struct AdvancedPrefsTab: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject private var helper = PrivilegedHelper.shared
    @State private var showResetAlert = false
    @State private var showUninstallAlert = false
    @State private var uninstallError: String?

    var body: some View {
        Form {
            Section("Helper Tool") {
                HStack {
                    Image(systemName: helper.isSetupComplete ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(helper.isSetupComplete ? Color.dnsSuccess : Color.dnsDanger)
                    Text(helper.isSetupComplete ? "Installed" : "Not installed")
                    Spacer()
                    Text("/usr/local/bin/dns-helper-tool")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }

                if helper.isSetupComplete {
                    Button("Uninstall Helper Tool", role: .destructive) {
                        showUninstallAlert = true
                    }
                    .alert("Uninstall Helper Tool", isPresented: $showUninstallAlert) {
                        Button("Uninstall", role: .destructive) {
                            uninstallHelper()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("The helper tool and sudoers rule will be removed. DNS and hosts operations will stop working.")
                    }
                } else {
                    Button("Reinstall") {
                        reinstallHelper()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                if let uninstallError {
                    Text(uninstallError)
                        .font(.caption)
                        .foregroundStyle(Color.dnsDanger)
                }
            }

            Section("Logging") {
                Picker("Log level", selection: $settings.logLevel) {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.label).tag(level)
                    }
                }

                Button("Open Log File") {
                    let logPath = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Library/Logs/DNS Helper.log")
                    NSWorkspace.shared.open(logPath)
                }
            }

            Section("Data") {
                HStack {
                    Text("Storage location")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("~/Library/NetShift/")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }

                Button("Open Storage Folder") {
                    let dir = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Library/NetShift")
                    NSWorkspace.shared.open(dir)
                }
            }

            Section {
                Button("Reset All Data", role: .destructive) {
                    showResetAlert = true
                }
                .alert("Reset All Data", isPresented: $showResetAlert) {
                    Button("Reset", role: .destructive) {
                        resetAllData()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("All hosts files and settings will be deleted. This action cannot be undone.")
                }
            }
        }
        .formStyle(.grouped)
        .padding(DesignTokens.Spacing.lg)
    }

    private func uninstallHelper() {
        do {
            try helper.uninstall()
            settings.helperInstalled = false
        } catch {
            uninstallError = error.localizedDescription
        }
    }

    private func reinstallHelper() {
        uninstallError = nil
        do {
            try helper.setup()
            settings.helperInstalled = true
        } catch {
            uninstallError = error.localizedDescription
        }
    }

    private func resetAllData() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/NetShift")
        try? FileManager.default.removeItem(at: dir)
        settings.hasCompletedOnboarding = false
    }
}
