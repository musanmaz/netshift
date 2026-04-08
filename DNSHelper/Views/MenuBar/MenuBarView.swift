import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var hostsManager: HostsFileManager
    @EnvironmentObject var dnsManager: DNSManager

    var body: some View {
        Group {
            if let active = hostsManager.activeFile {
                Label("Active: \(active.name)", systemImage: "checkmark.circle.fill")
                    .disabled(true)
            }

            Divider()

            Text("Hosts Files")
            ForEach(hostsManager.files) { file in
                Button {
                    activateHostsFile(file)
                } label: {
                    HStack {
                        if file.isActive {
                            Image(systemName: "checkmark")
                        }
                        Image(systemName: file.type.sfSymbol)
                        Text(file.name)
                    }
                }
            }

            Divider()

            Text("DNS Profiles")
            ForEach(dnsManager.profiles) { profile in
                Button {
                    switchDNSProfile(profile)
                } label: {
                    HStack {
                        if profile.isActive {
                            Image(systemName: "checkmark")
                        }
                        Text(profile.name)
                        Spacer()
                        Text(profile.primaryDNS)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("Reset to DHCP") {
                resetDNS()
            }

            Divider()

            Button("Sync Remote Files") {
                Task { await RemoteSyncService.shared.syncAllRemoteFiles() }
            }
            .disabled(hostsManager.remoteFiles.isEmpty)

            Divider()

            Button("Open Editor") {
                NotificationCenter.default.post(name: .openEditorWindow, object: nil)
            }
            .keyboardShortcut("e", modifiers: .command)

            SettingsLink {
                Text("Preferences...")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    private func activateHostsFile(_ file: HostsFile) {
        do {
            try hostsManager.activateFile(file)
        } catch {
            AppLogger.shared.error("Hosts activation error: \(error.localizedDescription)")
        }
    }

    private func switchDNSProfile(_ profile: DNSProfile) {
        do {
            try dnsManager.applyProfile(profile)
        } catch {
            AppLogger.shared.error("DNS switch error: \(error.localizedDescription)")
        }
    }

    private func resetDNS() {
        do {
            try dnsManager.resetToDHCP()
        } catch {
            AppLogger.shared.error("DNS reset error: \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let openEditorWindow = Notification.Name("openEditorWindow")
}
