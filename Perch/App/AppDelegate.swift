import AppKit

/// App delegate for the menu-bar (LSUIElement) lifecycle: hosts the
/// status item whose menu drives the dashboard window, settings and
/// quitting — the app has no Dock icon, so this is the control
/// surface.
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let dashboardWindowID = "Perch.Dashboard"
    static let openSettingsNotification = Notification.Name("PerchOpenSettings")

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "clock.fill",
            accessibilityDescription: "Perch"
        )

        let menu = NSMenu()
        let toggle = NSMenuItem(
            title: "显示 / 隐藏仪表盘",
            action: #selector(toggleDashboard),
            keyEquivalent: ""
        )
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        let settings = NSMenuItem(
            title: "设置…",
            action: #selector(openSettingsPanel),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let quit = NSMenuItem(
            title: "退出 Perch",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
    }

    /// Shows or hides the dashboard window (first launch keeps it
    /// visible; hiding keeps the app and the menu-bar item alive).
    @objc private func toggleDashboard() {
        guard let dashboard = dashboardWindow else { return }
        if dashboard.isVisible {
            dashboard.orderOut(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            dashboard.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func openSettingsPanel() {
        NotificationCenter.default.post(name: AppDelegate.openSettingsNotification, object: nil)
    }

    private var dashboardWindow: NSWindow? {
        WindowConfigurator.dashboardWindow
    }
}
