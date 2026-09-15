import SwiftUI

@main
struct PerchApp: App {
    @AppStorage(ConfigurationStore.appearanceKey) private var appearance: AppAppearance = .system

    var body: some Scene {
        WindowGroup("Perch") {
            DashboardView()
                .frame(
                    minWidth: DashboardLayout.minimumWindowWidth,
                    minHeight: DashboardLayout.minimumWindowHeight - DashboardLayout.titleBarAllowance
                )
                .background(WindowConfigurator())
                .preferredColorScheme(appearance.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)

        Settings {
            PerchSettingsView()
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
