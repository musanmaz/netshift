import SwiftUI

@main
struct DNSHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var hostsManager = HostsFileManager.shared
    @StateObject private var dnsManager = DNSManager.shared
    @StateObject private var settings = AppSettings.shared
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup("NetShift") {
            MainEditorView()
                .environmentObject(hostsManager)
                .environmentObject(dnsManager)
                .environmentObject(settings)
                .preferredColorScheme(settings.appearanceMode.colorScheme)
                .frame(
                    minWidth: DesignTokens.WindowSize.editorMinimum.width,
                    minHeight: DesignTokens.WindowSize.editorMinimum.height
                )
                .onAppear {
                    if !settings.hasCompletedOnboarding {
                        showOnboarding = true
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView {
                        settings.hasCompletedOnboarding = true
                        showOnboarding = false
                    }
                }
        }
        .defaultSize(
            width: DesignTokens.WindowSize.editorDefault.width,
            height: DesignTokens.WindowSize.editorDefault.height
        )
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(hostsManager)
                .environmentObject(dnsManager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: menuBarIcon)
                if settings.showFileNameInStatusBar, let name = hostsManager.activeFile?.name {
                    Text(name)
                        .font(.statusBarLabel)
                }
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            PreferencesView()
                .environmentObject(settings)
                .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
    }

    private var menuBarIcon: String {
        if dnsManager.isApplying {
            return "arrow.triangle.2.circlepath"
        }
        if hostsManager.activeFile != nil {
            return "network.badge.shield.half.filled"
        }
        return "network"
    }
}
