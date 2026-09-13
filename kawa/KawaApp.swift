import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize managers immediately so hotkeys work right away
        _ = InputSourceManager.shared
        _ = ShortcutManager.shared

        setupStatusBar()

        // If launched for the first time, show preferences
        let launchedKey = "kawa_has_launched_before"
        if !UserDefaults.standard.bool(forKey: launchedKey) {
            UserDefaults.standard.set(true, forKey: launchedKey)
            WindowManager.shared.showPreferences()
        }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }

        let image = NSImage(named: "StatusItemIcon")
        image?.isTemplate = true
        button.image = image
        button.toolTip = "Click to open Kawa Modern preferences"
        button.target = self
        button.action = #selector(statusBarClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            WindowManager.shared.togglePreferences()
            return
        }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferencesMenuAction), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit Kawa Modern", action: #selector(quitApp), keyEquivalent: "q"))

            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            WindowManager.shared.togglePreferences()
        }
    }

    @objc private func showPreferencesMenuAction() {
        WindowManager.shared.showPreferences()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

final class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()
    private var window: NSWindow?

    func togglePreferences() {
        if let win = window, win.isVisible {
            win.close()
        } else {
            showPreferences()
        }
    }

    func showPreferences() {
        if window == nil {
            let hostingController = NSHostingController(rootView: PreferencesView())
            let win = NSWindow(contentViewController: hostingController)
            win.title = "Kawa Modern Preferences"
            win.styleMask = [.titled, .closable]
            win.isReleasedWhenClosed = false
            win.delegate = self
            win.center()
            self.window = win
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        // Return focus to menu bar owning app
        NSWorkspace.shared.menuBarOwningApplication?.activate()
    }
}

@main
struct KawaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
    }
}
