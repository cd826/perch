import SwiftUI

/// The clock widget (SPEC §9, §12). Its column span follows the active
/// ClockStyle, so switching styles automatically reflows the grid.
struct ClockWidget: DashboardWidget {
    let style: ClockStyle

    var id: WidgetIdentifier { .clock }
    var columnSpan: Int { style.clockColumnSpan }
    var minimumWidth: CGFloat {
        style == .flip ? WidgetMinimumWidth.regular : WidgetMinimumWidth.compact
    }
    var preferredHeight: CGFloat { WidgetHeight.standard }

    var body: some View {
        switch style {
        case .analog:
            AnalogClockView()
        case .flip:
            FlipClockView()
        }
    }
}
