import SwiftUI

/// The dashboard surface (SPEC §8, §31): a quiet grid of cards on a
/// soft background. Composition comes entirely from the active
/// DashboardConfiguration; this view hard-codes nothing.
struct DashboardView: View {
    private let configuration = DashboardConfiguration.current

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
    }
}
