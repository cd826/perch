import CoreGraphics

/// Describes the current dashboard composition (SPEC §5, §8). The
/// clock style drives the whole arrangement: switching it changes the
/// clock's span and the weather's span, and the grid reflows without
/// any manual repositioning (SPEC §8.2, §12).
struct DashboardConfiguration {
    let clockStyle: ClockStyle

    /// The built-in V0.1 widgets in display order. The dashboard does
    /// not hard-code them; it renders whatever this list contains.
    var widgets: [any DashboardWidget] {
        [
            ClockWidget(style: clockStyle),
            TodoWidget(),
            WeatherWidget(columnSpan: clockStyle.weatherColumnSpan),
        ]
    }
}
