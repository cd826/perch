import CoreGraphics

/// Which built-in arrangement the dashboard uses (SPEC §8).
/// Phase 3 derives this from the persisted ClockStyle; for now the
/// dashboard always starts in the analog arrangement.
enum DashboardLayoutMode: String, CaseIterable {
    /// Clock 1 + Todo 1 + Weather 2 (SPEC §8.1).
    case analogClock
    /// Clock 2 + Todo 1 + Weather 1 (SPEC §8.2).
    case flipClock

    /// The column span of a widget under this layout mode. Switching
    /// modes changes spans, and the grid recalculates automatically.
    func columnSpan(for widget: WidgetIdentifier) -> Int {
        switch (self, widget) {
        case (.analogClock, .clock), (.analogClock, .todo):
            return WidgetColumnSpan.single
        case (.analogClock, .weather):
            return WidgetColumnSpan.double
        case (.flipClock, .clock):
            return WidgetColumnSpan.double
        case (.flipClock, .todo), (.flipClock, .weather):
            return WidgetColumnSpan.single
        }
    }
}

/// Describes the current dashboard composition (SPEC §5, §8).
struct DashboardConfiguration {
    let layoutMode: DashboardLayoutMode

    /// The built-in V0.1 widgets in display order. The dashboard does
    /// not hard-code them; it renders whatever this list contains.
    var widgets: [any DashboardWidget] {
        [
            ClockWidget(),
            TodoWidget(),
            WeatherWidget(),
        ]
    }

    /// V0.1 first round uses mock data in the analog arrangement.
    static let current = DashboardConfiguration(layoutMode: .analogClock)
}
