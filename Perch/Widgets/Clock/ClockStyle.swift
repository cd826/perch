import Foundation

/// The clock styles Perch V0.1 supports (SPEC §9.1). The raw value is
/// the persisted preference value (SPEC §24).
enum ClockStyle: String, CaseIterable {
    case analog
    case flip

    var displayName: String {
        switch self {
        case .analog: return "Analog"
        case .flip: return "Flip Clock"
        }
    }

    /// Analog occupies 1 column, Flip occupies 2 (SPEC §7.2, §8).
    /// Switching style changes this span, and the grid recalculates
    /// automatically (SPEC §12).
    var clockColumnSpan: Int {
        switch self {
        case .analog: return WidgetColumnSpan.single
        case .flip: return WidgetColumnSpan.double
        }
    }

    /// Weather fills whatever space the clock leaves (SPEC §8).
    var weatherColumnSpan: Int {
        switch self {
        case .analog: return WidgetColumnSpan.double
        case .flip: return WidgetColumnSpan.single
        }
    }
}
