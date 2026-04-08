import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenEditor),
            name: .openEditorWindow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenPreferences),
            name: .openPreferencesWindow,
            object: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.installWindowDelegates()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            showEditorWindow()
        }
        return true
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    // MARK: - Window Management

    @objc private func handleOpenEditor() {
        showEditorWindow()
    }

    @objc private func handleOpenPreferences() {
        showPreferencesWindow()
    }

    private func bringToFront(_ window: NSWindow) {
        window.delegate = self

        NSApp.setActivationPolicy(.regular)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            window.level = .floating
            window.makeKeyAndOrderFront(nil)

            NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                window.level = .normal
            }
        }
    }

    private func showEditorWindow() {
        if let window = findEditorWindow() {
            bringToFront(window)
        } else {
            NSApp.setActivationPolicy(.regular)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    if let w = self?.findEditorWindow() {
                        self?.bringToFront(w)
                    }
                }
            }
        }
    }

    private func showPreferencesWindow() {
        let existingWindows = Set(NSApp.windows.map { ObjectIdentifier($0) })

        NSApp.setActivationPolicy(.regular)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            if #available(macOS 14, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } else {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                // Find the settings window: either newly created, or any non-editor visible window
                let settingsWindow = NSApp.windows.first { window in
                    !existingWindows.contains(ObjectIdentifier(window)) && window.canBecomeMain
                } ?? NSApp.windows.first { window in
                    window.canBecomeMain && window.title != "NetShift" && window.isVisible
                } ?? NSApp.windows.first { window in
                    window.canBecomeMain && window.title != "NetShift"
                }

                if let window = settingsWindow {
                    self?.bringToFront(window)
                }
            }
        }
    }

    private func findEditorWindow() -> NSWindow? {
        NSApp.windows.first { window in
            window.title == "NetShift" && window.canBecomeMain
        }
    }

    private func installWindowDelegates() {
        for window in NSApp.windows where window.canBecomeMain {
            window.delegate = self
        }
    }
}
