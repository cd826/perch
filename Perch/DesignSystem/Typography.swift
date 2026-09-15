import SwiftUI

/// Shared type scale for the dashboard (SPEC §18, §2.2 glanceable).
enum Typography {
    /// Large numeric readouts.
    static let metricLarge = Font.system(size: 56, weight: .medium, design: .rounded)
    /// Secondary numeric readouts (todo count, mock clock digits).
    static let metric = Font.system(size: 40, weight: .medium, design: .rounded)
    /// Card titles (list name, city).
    static let widgetTitle = Font.system(size: 15, weight: .semibold, design: .rounded)
    /// Primary body text.
    static let body = Font.system(size: 14, weight: .regular)
    /// Small supporting text (hourly labels, captions).
    static let caption = Font.system(size: 12, weight: .regular)
}
