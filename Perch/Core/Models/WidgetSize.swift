import CoreGraphics

/// Column-span presets widgets declare (SPEC §7.2).
enum WidgetColumnSpan {
    static let single = 1
    static let double = 2
}

/// Width presets for the narrowest widget shapes.
enum WidgetMinimumWidth {
    static let compact: CGFloat = 200
    static let regular: CGFloat = 320
}
