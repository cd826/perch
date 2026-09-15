import SwiftUI

/// V0.1 settings (SPEC §21): clock style, the Reminders list the todo
/// card displays, and the weather location mode/city. All persist via
/// ConfigurationStore keys (SPEC §24).
struct PerchSettingsView: View {
    @AppStorage(ConfigurationStore.clockStyleKey) private var clockStyle: ClockStyle = .analog
    @ObservedObject private var reminderService = ReminderService.shared
    @ObservedObject private var locationService = LocationService.shared

    @State private var cityDraft = ""

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

            Section("天气") {
                weatherSection
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 480)
        .onAppear { cityDraft = locationService.manualCity }
    }

    // MARK: - Todo

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

    // MARK: - Weather

    @ViewBuilder private var weatherSection: some View {
        Picker("位置", selection: Binding(
            get: { locationService.mode },
            set: { locationService.setMode($0) }
        )) {
            ForEach(WeatherLocationMode.allCases, id: \.rawValue) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.radioGroup)
        .accessibilityLabel(Text("天气位置"))

        if locationService.mode == .manual {
            HStack {
                TextField("城市名，如 Guangzhou / 广州市", text: $cityDraft)
                    .onSubmit { locationService.setManualCity(cityDraft) }
                Button("应用") { locationService.setManualCity(cityDraft) }
                    .disabled(cityDraft.isEmpty)
            }
        }

        statusText
    }

    @ViewBuilder private var statusText: some View {
        switch locationService.state {
        case .denied:
            Text("定位权限被拒绝。请在系统设置中允许，或改用手动城市。")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        case .failed(let message):
            Text(message)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        case .resolved(let city):
            Text("当前城市：\(city)")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        case .locating:
            Text("正在定位…")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        case .idle:
            Text("尚未配置位置。")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}
