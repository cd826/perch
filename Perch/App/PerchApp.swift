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
                .background(WindowConfigurator())
        }
        .windowResizability(.contentMinSize)

        Settings {
            PerchSettingsView()
        }
    }
}
