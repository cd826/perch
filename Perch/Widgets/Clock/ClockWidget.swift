import SwiftUI

/// V0.1 first round: a static mock placeholder. Phase 3 replaces this
/// with the real Analog/Flip clock views and style switching; the
/// span wiring below is already the final architecture (SPEC §8, §12).
struct ClockWidget: DashboardWidget {
    var id: WidgetIdentifier { .clock }
    var columnSpan: Int { DashboardConfiguration.current.layoutMode.columnSpan(for: .clock) }
    var minimumWidth: CGFloat { WidgetMinimumWidth.compact }
    var preferredHeight: CGFloat { WidgetHeight.standard }

    var body: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "clock")
                .font(.system(size: 88, weight: .ultraLight))
                .foregroundStyle(.tint)
            Text("14:32")
                .font(Typography.metric)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
