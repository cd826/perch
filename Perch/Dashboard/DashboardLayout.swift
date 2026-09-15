import CoreGraphics

/// Geometry rules for the grid and window (SPEC §7, §20).
enum DashboardLayout {
    /// The default dashboard grid is 4 columns (SPEC §7.1).
    static let columnCount = 4
    /// Smallest comfortable width for a single grid column.
    static let minimumColumnWidth: CGFloat = 220

    static var minimumWindowWidth: CGFloat {
        windowWidth(forGridWidth: gridWidth(columnCount: columnCount, columnWidth: minimumColumnWidth))
    }
    static var defaultWindowWidth: CGFloat {
        windowWidth(forGridWidth: gridWidth(columnCount: columnCount, columnWidth: 300))
    }
    static var minimumWindowHeight: CGFloat { 480 }
    static var defaultWindowHeight: CGFloat { 720 }

    private static func gridWidth(columnCount: Int, columnWidth: CGFloat) -> CGFloat {
        CGFloat(columnCount) * columnWidth + CGFloat(columnCount - 1) * Spacing.gridGap
    }

    private static func windowWidth(forGridWidth gridWidth: CGFloat) -> CGFloat {
        gridWidth + Spacing.dashboardPadding * 2
    }
}
