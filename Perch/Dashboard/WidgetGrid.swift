import SwiftUI

private struct ColumnSpanKey: LayoutValueKey {
    static let defaultValue = 1
}

private struct PreferredHeightKey: LayoutValueKey {
    static let defaultValue = CGFloat.zero
}

extension View {
    /// Declares how many grid columns this view occupies (SPEC §7.2).
    func gridColumnSpan(_ span: Int) -> some View {
        layoutValue(key: ColumnSpanKey.self, value: max(span, 1))
    }

    /// Declares the height this view prefers inside its grid row.
    func gridPreferredHeight(_ height: CGFloat) -> some View {
        layoutValue(key: PreferredHeightKey.self, value: height)
    }
}

/// A fixed-column responsive grid (SPEC §7): children are placed left
/// to right and wrap to a new row when the current row runs out of
/// columns. The grid knows nothing about widget internals — children
/// carry their own span and preferred height via the modifiers above.
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
            let itemWidth = columnWidth * CGFloat(span) + spacing * CGFloat(span - 1)
            let intrinsic = subview.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil))
            let preferred = subview[PreferredHeightKey.self]
            current.items.append((subview, span))
            current.spanTotal += span
            current.height = max(current.height, preferred > 0 ? preferred : intrinsic.height)
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
