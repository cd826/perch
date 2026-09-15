import CoreGraphics

/// Geometry rules for the grid and window (SPEC §7, §20).
/// Rows are square by default, so window height derives from the
/// column width rather than fixed constants.
enum DashboardLayout {
    /// The default dashboard grid is 4 columns (SPEC §7.1).
    static let columnCount = 4
    /// Smallest comfortable width for a single grid column. Chosen so
    /// the minimum window fits a 800pt-wide display exactly.
    static let minimumColumnWidth: CGFloat = 176
    /// Column width the default window size targets.
    static let defaultColumnWidth: CGFloat = 300
    /// Height the hidden titlebar still adds to the window frame.
    /// SwiftUI's contentMinSize double-counts it on full-size-content
    /// windows, so the SwiftUI content minimum subtracts it.
    static let titleBarAllowance: CGFloat = 28

    static var minimumWindowWidth: CGFloat {
        windowWidth(forGridWidth: gridWidth(columnCount: columnCount, columnWidth: minimumColumnWidth))
    }
    static var defaultWindowWidth: CGFloat {
        windowWidth(forGridWidth: gridWidth(columnCount: columnCount, columnWidth: defaultColumnWidth))
    }
    static var minimumWindowHeight: CGFloat {
        minimumColumnWidth + Spacing.dashboardPadding * 2
    }
    static var defaultWindowHeight: CGFloat {
        defaultColumnWidth + Spacing.dashboardPadding * 2 + 32  // + window title bar
    }

    private static func gridWidth(columnCount: Int, columnWidth: CGFloat) -> CGFloat {
        CGFloat(columnCount) * columnWidth + CGFloat(columnCount - 1) * Spacing.gridGap
    }

    private static func windowWidth(forGridWidth gridWidth: CGFloat) -> CGFloat {
        gridWidth + Spacing.dashboardPadding * 2
    }
}
