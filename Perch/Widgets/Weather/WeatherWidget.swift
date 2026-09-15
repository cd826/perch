import AppKit
import SwiftUI

/// Weather card backed by LocationService + WeatherService (SPEC
/// §14–17). Renders every SPEC §22 situation — permission prompt,
/// setup guidance, failure with last-updated time — and the live
/// snapshot in a wide (2-column) or compact (1-column) layout.
struct WeatherWidget: DashboardWidget {
    @StateObject private var viewModel = WeatherViewModel()

    var id: WidgetIdentifier { .weather }
    let columnSpan: Int
    var minimumWidth: CGFloat { WidgetMinimumWidth.regular }

    init(columnSpan: Int) {
        self.columnSpan = columnSpan
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                header
                // Compressible body: the card must never stretch beyond
                // its square row, whatever the content's minimum height.
                detail
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header

    @ViewBuilder private var header: some View {
        switch viewModel.state {
        case .loaded(let snapshot, _):
            Text(snapshot.city)
                .font(Typography.widgetTitle)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        default:
            Text("天气")
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

        case .needsLocationPermission:
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("启用定位显示当地天气，或在设置中手动输入城市。")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Button("启用定位") { viewModel.requestLocationAccess() }
                    .controlSize(.small)
            }

        case .setupRequired:
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("在设置中启用定位，或手动输入要显示天气的城市。")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                Button("打开设置") { Self.openAppSettings() }
                    .controlSize(.small)
            }

        case .failed(let message, let snapshot):
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("天气数据不可用。")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let snapshot {
                    lastUpdatedText(for: snapshot)
                    miniSnapshot(snapshot)
                }
                Button("重试") { viewModel.refreshNow() }
                    .controlSize(.small)
            }

        case .loaded(let snapshot, let staleNotice):
            if columnSpan >= WidgetColumnSpan.double {
                wideLayout(snapshot)
            } else {
                compactLayout(snapshot)
            }
            if let staleNotice {
                Text(staleNotice)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Data layouts

    /// Two-column layout, styled like the macOS weather widget:
    /// city and current temperature on the left, condition and range
    /// on the right, hourly strip along the bottom.
    private func wideLayout(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(snapshot.temperature)°")
                        .font(Typography.temperatureLarge)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: snapshot.symbolName)
                        .font(.system(size: 15))
                        .foregroundStyle(.tint)
                    Text(snapshot.condition)
                        .font(Typography.caption)
                        .lineLimit(1)
                    HStack(spacing: Spacing.xs) {
                        Text("H:\(snapshot.high)°")
                        Text("L:\(snapshot.low)°")
                    }
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            }
            Divider()
            hourlyStrip(Array(snapshot.hourly.prefix(6)))
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// One-column layout for narrow cards: current conditions above a
    /// shorter hourly strip; the condition line is dropped — it does
    /// not fit a 1-column card.
    private func compactLayout(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text("\(snapshot.temperature)°")
                    .font(Typography.temperatureCompact)
                Spacer(minLength: Spacing.small)
                Text("H:\(snapshot.high)° L:\(snapshot.low)°")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Divider()
            hourlyStrip(itemCount: 4, from: snapshot.hourly)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func hourlyStrip(_ entries: [WeatherSnapshot.HourEntry]) -> some View {
        HStack(spacing: Spacing.small) {
            ForEach(entries) { entry in
                VStack(spacing: 2) {
                    Text(entry.hour)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: entry.symbolName)
                            .font(.system(size: 12))
                            .foregroundStyle(.tint)
                        Text("\(entry.temperature)°")
                            .font(Typography.caption)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func hourlyStrip(itemCount: Int, from entries: [WeatherSnapshot.HourEntry]) -> some View {
        hourlyStrip(Array(entries.prefix(itemCount)))
    }

    private func lastUpdatedText(for snapshot: WeatherSnapshot) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return Text("最后更新：\(formatter.string(from: snapshot.fetchedAt))")
            .font(Typography.caption)
            .foregroundStyle(.secondary)
    }

    private func miniSnapshot(_ snapshot: WeatherSnapshot) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: snapshot.symbolName)
                .foregroundStyle(.tint)
            Text("\(snapshot.temperature)°")
                .monospacedDigit()
        }
        .font(Typography.caption)
    }

    // MARK: - Helpers

    private var accessibilityLabel: String {
        switch viewModel.state {
        case .loaded(let snapshot, _):
            return "天气 \(snapshot.city)，\(snapshot.temperature) 度，\(snapshot.condition)"
        case .needsLocationPermission:
            return "天气，需要定位权限"
        default:
            return "天气"
        }
    }

    private static func openAppSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }
}
