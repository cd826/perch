import AppKit
import SwiftUI

/// Weather card backed by LocationService + WeatherService (SPEC
/// §14–17). Renders every SPEC §22 situation — permission prompt,
/// setup guidance, failure with last-updated time — and the live
/// snapshot in a wide (2-column) or compact (1-column) layout.
/// Content fills the square card: info block pinned to the top,
/// hourly strip pinned to the bottom, flexible space between.
struct WeatherWidget: DashboardWidget {
    @StateObject private var viewModel = WeatherViewModel()

    var id: WidgetIdentifier { .weather }
    let columnSpan: Int
    var minimumWidth: CGFloat { WidgetMinimumWidth.regular }

    init(columnSpan: Int) {
        self.columnSpan = columnSpan
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    header
                    stateContent
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .topLeading)
            }
            .scrollIndicators(.never)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header

    @ViewBuilder private var header: some View {
        switch viewModel.state {
        // Loaded states render the city inside their own layout.
        case .loaded, .failed:
            EmptyView()
        default:
            Text("天气")
                .font(Typography.widgetTitle)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Body per state

    @ViewBuilder private var stateContent: some View {
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
            let isWide = columnSpan >= WidgetColumnSpan.double
            VStack(alignment: .leading, spacing: 6) {
                if let staleNotice {
                    Text(staleNotice)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if isWide {
                    wideTop(snapshot)
                } else {
                    compactTop(snapshot)
                }
                Spacer(minLength: 0)
                hourlyStrip(Array(snapshot.hourly.prefix(isWide ? 6 : 3)))
            }
        }
    }

    // MARK: - Data layouts

    /// Two-column top section modeled on the macOS weather widget:
    /// city, condition and range on the left, oversized temperature
    /// pinned to the top-right corner. Every line is left-aligned to
    /// the city name.
    private func wideTop(_ snapshot: WeatherSnapshot) -> some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.city)
                    .font(Typography.widgetTitle)
                HStack(spacing: 6) {
                    Text(snapshot.condition)
                        .font(Typography.body)
                    Image(systemName: snapshot.symbolName)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                }
                HStack(spacing: 8) {
                    rangeText("最高", snapshot.high)
                    rangeText("最低", snapshot.low)
                }
            }
            Spacer(minLength: 0)
            Text("\(snapshot.temperature)°")
                .font(Typography.temperatureLarge)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// One-column top section: city top-left with temperature
    /// top-right (both flush with the card's top edge, matching the
    /// neighbouring todo title), then full-width condition and
    /// text-style high/low rows. Sizes chosen so the hourly strip's
    /// temperature row stays visible in the square card.
    private func compactTop(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: Spacing.small) {
                Text(snapshot.city)
                    .font(Typography.widgetTitle)
                    .lineLimit(1)
                Spacer(minLength: Spacing.small)
                Text("\(snapshot.temperature)°")
                    .font(Typography.temperatureCompact)
            }
            HStack(spacing: 4) {
                Text(snapshot.condition)
                    .font(Typography.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: snapshot.symbolName)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
            }
            HStack(spacing: 8) {
                rangeText("最高", snapshot.high)
                rangeText("最低", snapshot.low)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// "最高32°"-style readout on a single line.
    private func rangeText(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
            Text("\(value)°")
                .font(Typography.caption)
                .monospacedDigit()
        }
    }

    /// Hourly strip justified like the macOS weather widget: the
    /// first column hugs the card's left baseline (under the city),
    /// the last hugs the right edge, and the gaps between columns are
    /// exactly equal (flexible spacers share the leftover width).
    /// Within a column, time/icon/temperature share one center axis.
    private func hourlyStrip(_ entries: [WeatherSnapshot.HourEntry]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                VStack(alignment: .center, spacing: 2) {
                    Text("\(entry.hour)时")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                    Image(systemName: entry.symbolName)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .frame(width: 20)
                    Text("\(entry.temperature)°")
                        .font(Typography.caption)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                }
                if index < entries.count - 1 {
                    Spacer(minLength: Spacing.small)
                }
            }
        }
        .frame(maxWidth: .infinity)
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
