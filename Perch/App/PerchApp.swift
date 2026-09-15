import SwiftUI

@main
struct PerchApp: App {
    var body: some Scene {
        WindowGroup("Perch") {
            DashboardView()
                .frame(
                    minWidth: DashboardLayout.minimumWindowWidth,
                    minHeight: DashboardLayout.minimumWindowHeight
                )
        }
        .defaultSize(
            width: DashboardLayout.defaultWindowWidth,
            height: DashboardLayout.defaultWindowHeight
        )
        .windowResizability(.contentMinSize)
    }
}
