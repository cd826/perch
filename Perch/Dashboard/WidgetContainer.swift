import SwiftUI

/// Bridges a widget to the grid (SPEC §6, §18): wraps the widget's
/// content in the shared DashboardCard and applies the widget's
/// span/height metadata as layout hints. The grid only ever sees
/// containers, never widget internals.
struct WidgetContainer: View {
    let widget: any DashboardWidget

    var body: some View {
        DashboardCard {
            widget.asAnyView
        }
        .gridColumnSpan(widget.columnSpan)
        .gridHeightRatio(widget.heightRatio)
    }
}
