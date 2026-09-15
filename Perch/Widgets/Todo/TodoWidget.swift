import SwiftUI

/// V0.1 first round: mock reminder data (SPEC §13.3). Phase 4 replaces
/// the mock list with ReminderService (EventKit). The list lives in a
/// ScrollView so any number of tasks fits inside the square card:
/// long titles truncate with "…" and overflow tasks scroll.
struct TodoWidget: DashboardWidget {
    var id: WidgetIdentifier { .todo }
    var columnSpan: Int { WidgetColumnSpan.single }
    var minimumWidth: CGFloat { WidgetMinimumWidth.compact }

    private let listName = "待办"
    private let mockTasks = [
        "Review PR",
        "Reply to email",
        "Submit report",
        "Prepare the weekly design review deck",
        "Book meeting room for Thursday",
        "Buy printer ink",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(listName)
                .font(Typography.widgetTitle)
            + Text("(\(mockTasks.count))")
                .font(Typography.widgetTitle)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(mockTasks, id: \.self) { task in
                        HStack(spacing: Spacing.small) {
                            Circle()
                                .strokeBorder(.secondary, lineWidth: 1.5)
                                .frame(width: 12, height: 12)
                            Text(task)
                                .font(Typography.body)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.automatic)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
