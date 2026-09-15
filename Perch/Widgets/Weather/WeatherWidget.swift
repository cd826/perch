import SwiftUI

private struct MockHourForecast: Identifiable {
    let hour: String
    let symbol: String
    let temperature: String

    var id: String { hour }
}

/// V0.1 first round: mock weather matching the SPEC §16 example,
/// sized for a 2-column card. Phase 5 swaps the mock values for
/// WeatherService data; the display structure stays as-is. Its span
/// is injected by the dashboard configuration — weather fills the
/// space the clock style leaves free (SPEC §8).
struct WeatherWidget: DashboardWidget {
    var id: WidgetIdentifier { .weather }
    let columnSpan: Int
    var minimumWidth: CGFloat { WidgetMinimumWidth.regular }
    var preferredHeight: CGFloat { WidgetHeight.standard }

    private let city = "Guangzhou"
    private let temperature = "31°"
    private let condition = "Mostly Clear"
    private let dailyRange = "H:33°  L:26°"
    private let hourly: [MockHourForecast] = [
        .init(hour: "12", symbol: "sun.max", temperature: "32°"),
        .init(hour: "13", symbol: "cloud.sun", temperature: "32°"),
        .init(hour: "14", symbol: "cloud", temperature: "33°"),
        .init(hour: "15", symbol: "cloud", temperature: "31°"),
        .init(hour: "16", symbol: "cloud", temperature: "29°"),
        .init(hour: "17", symbol: "cloud.drizzle", temperature: "27°"),
    ]

    var body: some View {
        if columnSpan >= WidgetColumnSpan.double {
            wideLayout
        } else {
            compactLayout
        }
    }

    /// Two-column layout: current conditions beside the hourly strip.
    private var wideLayout: some View {
        HStack(alignment: .center, spacing: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(city)
                    .font(Typography.widgetTitle)
                    .foregroundStyle(.secondary)
                Text(temperature)
                    .font(Typography.metricLarge)
                Text(condition)
                    .font(Typography.body)
                Text(dailyRange)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Divider()
            HStack(spacing: Spacing.small) {
                ForEach(hourly) { item in
                    VStack(spacing: Spacing.small) {
                        Text(item.hour)
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .fixedSize()
                        Image(systemName: item.symbol)
                            .font(.system(size: 22))
                            .foregroundStyle(.tint)
                        Text(item.temperature)
                            .font(Typography.caption)
                            .monospacedDigit()
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// One-column layout: current conditions above a shorter hourly strip.
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .center, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(city)
                        .font(Typography.widgetTitle)
                        .foregroundStyle(.secondary)
                    Text(condition)
                        .font(Typography.body)
                    Text(dailyRange)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text(temperature)
                    .font(Typography.metric)
            }
            Divider()
            HStack(spacing: Spacing.small) {
                ForEach(hourly.prefix(4)) { item in
                    VStack(spacing: Spacing.xs) {
                        Text(item.hour)
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                        Image(systemName: item.symbol)
                            .font(.system(size: 15))
                            .foregroundStyle(.tint)
                        Text(item.temperature)
                            .font(Typography.caption)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
