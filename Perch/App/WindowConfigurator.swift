import AppKit
import SwiftUI

/// AppKit window plumbing (SPEC §4 — window behavior): applies the
/// ambient-app chrome (no title bar, traffic lights floating over
/// full-size content, background dragging) plus the default frame on
/// first launch. SwiftUI's `.defaultSize` is not honored for
/// WindowGroup on current macOS, hence this hook.
struct WindowConfigurator: NSViewRepresentable {
    private static let frameAutosaveName = "Perch.MainWindow"

    /// Weak ref to the dashboard window, set once the view lands in
    /// it — the menu-bar toggle uses this instead of searching
    /// NSApp.windows by identifier (unreliable under SwiftUI).
    static weak var dashboardWindow: NSWindow?

    func makeNSView(context: Context) -> NSView {
        ChromeApplyingView(frameAutosaveName: Self.frameAutosaveName)
    }

    func updateNSView(_ view: NSView, context: Context) {}
}

/// Applies window settings in viewDidMoveToWindow — deterministic,
/// unlike a DispatchQueue hop whose view.window can still be nil.
private final class ChromeApplyingView: NSView {
    private let frameAutosaveName: String
    private var didConfigure = false

    init(frameAutosaveName: String) {
        self.frameAutosaveName = frameAutosaveName
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, !didConfigure else { return }
        didConfigure = true

        WindowConfigurator.dashboardWindow = window

        // Title-bar chrome itself comes from .windowStyle(.hiddenTitleBar)
        // on the scene; this hook handles the parts SwiftUI does not
        // expose (precise minimum size, frame autosaving, dragging).
        window.identifier = NSUserInterfaceItemIdentifier(AppDelegate.dashboardWindowID)
        window.isMovableByWindowBackground = true
        // SwiftUI's contentMinSize double-counts the hidden titlebar
        // (28pt) on full-size-content windows, making the minimum
        // window taller than the content and the vertical gaps larger
        // than the horizontal ones. Set the window minimum directly.
        window.contentMinSize = .zero
        window.minSize = NSSize(
            width: DashboardLayout.minimumWindowWidth,
            height: DashboardLayout.minimumWindowHeight
        )

        window.setFrameAutosaveName(frameAutosaveName)
        if !window.setFrameUsingName(frameAutosaveName) {
            // First launch: default size, clamped to the visible
            // frame of the screen the window lands on.
            let visible = window.screen?.visibleFrame
            let width = min(DashboardLayout.defaultWindowWidth, visible?.width ?? .infinity)
            let height = min(DashboardLayout.defaultWindowHeight, visible?.height ?? .infinity)
            window.setContentSize(NSSize(width: width, height: height))
            window.center()
        }
    }
}
