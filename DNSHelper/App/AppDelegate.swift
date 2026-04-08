import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenEditor),
            name: .openEditorWindow,
            object: nil
        )
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            showEditorWindow()
        }
        return true
    }

    @objc private func handleOpenEditor() {
        showEditorWindow()
    }

    private func showEditorWindow() {
        NSApp.activate(ignoringOtherApps: true)

        let found = NSApp.windows.first { window in
            window.title == "NetShift" && window.canBecomeMain
        }

        if let found {
            found.makeKeyAndOrderFront(nil)
        } else {
            NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
        }
    }
}
