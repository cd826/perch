import SwiftUI

/// Shared type scale for the dashboard (SPEC §18, §2.2 glanceable).
enum Typography {
    /// Hero temperature readout (weather widget).
    static let temperatureLarge = Font.system(size: 64, weight: .medium, design: .rounded)
    /// Secondary numeric readouts (todo count, compact temperature).
    static let metric = Font.system(size: 40, weight: .medium, design: .rounded)
    /// Flip clock digits.
    static let flipDigit = Font.system(size: 64, weight: .semibold, design: .rounded)
    /// Card titles (list name, city).
    static let widgetTitle = Font.system(size: 15, weight: .semibold, design: .rounded)
    /// Primary body text.
    static let body = Font.system(size: 14, weight: .regular)
    /// Small supporting text (hourly labels, captions).
    static let caption = Font.system(size: 12, weight: .regular)
}
