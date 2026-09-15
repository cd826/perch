import SwiftUI

/// The dashboard surface (SPEC §8, §31): a quiet grid of cards on a
/// soft background. Composition comes entirely from the active
/// DashboardConfiguration; this view hard-codes nothing. The clock
/// style is persisted and read here, so changing it in Settings
/// rebuilds the configuration and animates the grid reflow (SPEC §12).
struct DashboardView: View {
    @AppStorage(ConfigurationStore.clockStyleKey) private var clockStyle: ClockStyle = .analog

    private var configuration: DashboardConfiguration {
        DashboardConfiguration(clockStyle: clockStyle)
    }

    var body: some View {
        ZStack {
            DashboardBackground()
            WidgetGrid(columnCount: DashboardLayout.columnCount, spacing: Spacing.gridGap) {
                ForEach(configuration.widgets, id: \.id) { widget in
                    WidgetContainer(widget: widget)
                }
            }
            .padding(Spacing.dashboardPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.35), value: clockStyle)
    }
}
