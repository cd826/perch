import SwiftUI

/// V0.1 first round: mock reminder data shaped like the final display
/// (SPEC §13.3). Phase 4 replaces the mock list with ReminderService
/// (EventKit); the display structure stays as-is.
struct TodoWidget: DashboardWidget {
    var id: WidgetIdentifier { .todo }
    var columnSpan: Int { DashboardConfiguration.current.layoutMode.columnSpan(for: .todo) }
    var minimumWidth: CGFloat { WidgetMinimumWidth.compact }
    var preferredHeight: CGFloat { WidgetHeight.standard }

    private let listName = "Work"
    private let mockTasks = ["Review PR", "Reply to email", "Submit report"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(listName)
                .font(Typography.widgetTitle)
                .foregroundStyle(.secondary)
            Text("\(mockTasks.count)")
                .font(Typography.metric)
                .foregroundStyle(.tint)
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
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
