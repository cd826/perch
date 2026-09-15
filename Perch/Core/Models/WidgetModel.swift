import SwiftUI

/// Identifies the built-in dashboard widgets (SPEC §1.3, §6).
enum WidgetIdentifier: String, CaseIterable, Hashable {
    case clock
    case todo
    case weather
}

/// The contract every dashboard widget conforms to (SPEC §6.1, §6.2).
///
/// The grid only sees this interface — it never knows a widget's
/// internal implementation, so future widgets (Agent, Calendar, …)
/// can be added without restructuring the dashboard.
protocol DashboardWidget: View {
    /// Stable identity used by the grid and persistence.
    var id: WidgetIdentifier { get }
    /// How many grid columns this widget occupies.
    var columnSpan: Int { get }
    /// Smallest width the widget stays usable at.
    var minimumWidth: CGFloat { get }
    /// Height the widget prefers inside its grid row.
    var preferredHeight: CGFloat { get }
}

extension DashboardWidget {
    /// Type-erased view so heterogeneous widgets can share one collection.
    var asAnyView: AnyView { AnyView(self) }
}
