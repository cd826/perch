import CoreGraphics

/// Column-span presets widgets declare (SPEC §7.2).
enum WidgetColumnSpan {
    static let single = 1
    static let double = 2
}

/// Row height presets so the V0.1 single-row layout stays aligned.
enum WidgetHeight {
    static let standard: CGFloat = 320
}

/// Width presets for the narrowest widget shapes.
enum WidgetMinimumWidth {
    static let compact: CGFloat = 200
    static let regular: CGFloat = 320
}
