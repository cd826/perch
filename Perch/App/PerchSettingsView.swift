import SwiftUI

/// V0.1 settings (SPEC §21): intentionally minimal — clock style only.
/// Future sections (Todo list, Weather location, Appearance) will be
/// appended here. Persisted via the same key the dashboard reads, so a
/// change here reflows the layout immediately (SPEC §12).
struct PerchSettingsView: View {
    @AppStorage(ConfigurationStore.clockStyleKey) private var clockStyle: ClockStyle = .analog

    var body: some View {
        Form {
            Picker("Clock Style", selection: $clockStyle) {
                ForEach(ClockStyle.allCases, id: \.self) { style in
                    Text(style.displayName)
                        .tag(style)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 140)
    }
}
