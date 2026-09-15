import AppKit
import SwiftUI

/// AppKit window plumbing (SPEC §4 — window behavior): applies the
/// default frame on first launch and then hands over to macOS frame
/// autosaving, so the user's own size/position is remembered across
/// launches. SwiftUI's `.defaultSize` is not honored for WindowGroup
/// on current macOS, hence this hook.
struct WindowConfigurator: NSViewRepresentable {
    private static let frameAutosaveName = "Perch.MainWindow"

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.setFrameAutosaveName(Self.frameAutosaveName)
            if !window.setFrameUsingName(Self.frameAutosaveName) {
                // First launch: default size, clamped to the visible
                // frame of the screen the window lands on.
                let visible = window.screen?.visibleFrame
                let width = min(DashboardLayout.defaultWindowWidth, visible?.width ?? .infinity)
                let height = min(DashboardLayout.defaultWindowHeight, visible?.height ?? .infinity)
                window.setContentSize(NSSize(width: width, height: height))
                window.center()
            }
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}
}
