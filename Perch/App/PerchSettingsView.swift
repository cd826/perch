import SwiftUI

/// V0.1 settings (SPEC §21): clock style plus the Reminders list the
/// todo card displays. Both persist via ConfigurationStore keys.
struct PerchSettingsView: View {
    @AppStorage(ConfigurationStore.clockStyleKey) private var clockStyle: ClockStyle = .analog
    @ObservedObject private var reminderService = ReminderService.shared

    var body: some View {
        Form {
            Section("时钟") {
                Picker("风格", selection: $clockStyle) {
                    ForEach(ClockStyle.allCases, id: \.self) { style in
                        Text(style.displayName)
                            .tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("提醒事项") {
                todoSection
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 300)
    }

    @ViewBuilder private var todoSection: some View {
        switch reminderService.status {
        case .authorized:
            Picker("列表", selection: Binding(
                get: { reminderService.selectedListID ?? "" },
                set: { reminderService.selectList($0.isEmpty ? nil : $0) }
            )) {
                if reminderService.lists.isEmpty {
                    Text("默认").tag("")
                }
                ForEach(reminderService.lists) { list in
                    Text(list.title).tag(list.id)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel(Text("提醒事项列表"))

        case .notDetermined:
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("允许访问提醒事项后，可以选择要显示的列表。")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                Button("允许访问") { reminderService.requestAccess() }
                    .controlSize(.small)
            }

        case .denied:
            Text("提醒事项访问被拒绝，请在系统设置中允许 Perch 访问。")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}
