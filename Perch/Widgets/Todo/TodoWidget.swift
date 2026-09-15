import AppKit
import SwiftUI

/// Todo card backed by macOS Reminders (SPEC §13). The permission
/// prompt, denial and error states are first-class (SPEC §13.2, §22);
/// the task list lives in a ScrollView so overflow never stretches
/// the square card.
struct TodoWidget: DashboardWidget {
    @StateObject private var viewModel = TodoViewModel()

    var id: WidgetIdentifier { .todo }
    var columnSpan: Int { WidgetColumnSpan.single }
    var minimumWidth: CGFloat { WidgetMinimumWidth.compact }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            header
            detail
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header

    @ViewBuilder private var header: some View {
        switch viewModel.state {
        case .content(let listTitle, let tasks):
            Text("\(listTitle)(\(tasks.count))")
                .font(Typography.widgetTitle)
        case .empty(let listTitle):
            Text("\(listTitle)(0)")
                .font(Typography.widgetTitle)
        case .loading, .needsPermission, .accessDenied, .unavailable, .noLists:
            Text("待办")
                .font(Typography.widgetTitle)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Body per state

    @ViewBuilder private var detail: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .controlSize(.small)

        case .needsPermission:
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("允许访问提醒事项，在仪表盘上显示你的待办。")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                Button("允许访问") { viewModel.requestAccess() }
                    .controlSize(.small)
            }

        case .accessDenied:
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("提醒事项访问被拒绝。请在系统设置中允许 Perch 访问提醒事项。")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                Button("打开系统设置") { Self.openRemindersPrivacySettings() }
                    .controlSize(.small)
            }

        case .unavailable(let message):
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("无法加载提醒事项。")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                if !message.isEmpty {
                    Text(message)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Button("重试") { viewModel.reload() }
                    .controlSize(.small)
            }

        case .noLists:
            Text("没有提醒事项列表。")
                .font(Typography.body)
                .foregroundStyle(.secondary)

        case .empty:
            Text("全部完成")
                .font(Typography.body)
                .foregroundStyle(.secondary)

        case .content(_, let tasks):
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(tasks) { task in
                        HStack(spacing: Spacing.small) {
                            Circle()
                                .strokeBorder(.secondary, lineWidth: 1.5)
                                .frame(width: 12, height: 12)
                            Text(task.title)
                                .font(Typography.body)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.automatic)
        }
    }

    // MARK: - Helpers

    private var accessibilityLabel: String {
        switch viewModel.state {
        case .content(let listTitle, let tasks):
            return "待办列表 \(listTitle)，\(tasks.count) 项未完成"
        case .empty(let listTitle):
            return "待办列表 \(listTitle)，全部完成"
        case .needsPermission:
            return "待办，需要提醒事项访问权限"
        case .accessDenied:
            return "待办，提醒事项访问被拒绝"
        default:
            return "待办"
        }
    }

    private static func openRemindersPrivacySettings() {
        let addresses = [
            "x-apple.systempreferences:com.apple.settings.privacy?Privacy_Reminders",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders",
        ]
        for address in addresses {
            if let url = URL(string: address), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
