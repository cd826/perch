import CoreGraphics

/// Shared spacing rhythm for the dashboard (SPEC §18).
enum Spacing {
    /// Tight inline gaps (icon ↔ label).
    static let xs = CGFloat(4)
    /// Related element gaps (list rows).
    static let small = CGFloat(8)
    /// Card internal rhythm and grid gaps.
    static let medium = CGFloat(16)
    /// Dashboard margins and block separation.
    static let large = CGFloat(24)

    /// Gap between grid items.
    static let gridGap = CGFloat(16)
    /// Interior padding of a dashboard card.
    static let cardPadding = CGFloat(20)
    /// Corner radius shared by every card (SPEC §18).
    static let cardCornerRadius = CGFloat(24)
    /// Outer margin around the widget grid.
    static let dashboardPadding = CGFloat(24)
}
