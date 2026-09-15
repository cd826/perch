import SwiftUI

private struct ColumnSpanKey: LayoutValueKey {
    static let defaultValue = 1
}

private struct HeightRatioKey: LayoutValueKey {
    static let defaultValue: CGFloat = 1
}

extension View {
    /// Declares how many grid columns this view occupies (SPEC §7.2).
    func gridColumnSpan(_ span: Int) -> some View {
        layoutValue(key: ColumnSpanKey.self, value: max(span, 1))
    }

    /// Declares the row height as a multiple of the column width
    /// (1 = square, like macOS desktop widgets).
    func gridHeightRatio(_ ratio: CGFloat) -> some View {
        layoutValue(key: HeightRatioKey.self, value: max(ratio, 0.1))
    }
}

/// A fixed-column responsive grid (SPEC §7): children are placed left
/// to right and wrap to a new row when the current row runs out of
/// columns. Row height follows the column width so cards keep macOS
/// widget proportions (square for 1 column, ~2:1 for 2 columns).
/// The grid knows nothing about widget internals — children carry
/// their own span and height ratio via the modifiers above.
struct WidgetGrid: Layout {
    var columnCount: Int
    var spacing: CGFloat

    private struct Row {
        var items: [(subview: LayoutSubview, span: Int)] = []
        var spanTotal = 0
        var height = CGFloat.zero
    }

    private func arrange(proposalWidth: CGFloat, subviews: Subviews) -> (rows: [Row], columnWidth: CGFloat) {
        let usableWidth = max(proposalWidth - spacing * CGFloat(columnCount - 1), 0)
        let columnWidth = usableWidth / CGFloat(columnCount)

        var rows: [Row] = []
        var current = Row()

        for subview in subviews {
            let span = min(max(subview[ColumnSpanKey.self], 1), columnCount)
            if current.spanTotal + span > columnCount, !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.items.append((subview, span))
            current.spanTotal += span
            let rowHeight = columnWidth * subview[HeightRatioKey.self]
            current.height = max(current.height, rowHeight)
        }
        if !current.items.isEmpty { rows.append(current) }
        return (rows, columnWidth)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let width = proposal.width, width > 0 else { return .zero }
        let (rows, _) = arrange(proposalWidth: width, subviews: subviews)
        let totalHeight = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let width = proposal.width, width > 0 else { return }
        let (rows, columnWidth) = arrange(proposalWidth: width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let itemWidth = columnWidth * CGFloat(item.span) + spacing * CGFloat(item.span - 1)
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: itemWidth, height: row.height)
                )
                x += itemWidth + spacing
            }
            y += row.height + spacing
        }
    }
}
