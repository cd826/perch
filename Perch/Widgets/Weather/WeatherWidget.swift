import SwiftUI

private struct MockHourForecast: Identifiable {
    let hour: String
    let symbol: String
    let temperature: String

    var id: String { hour }
}

/// V0.1 first round: mock weather matching the SPEC §16 example,
/// sized for a 2-column card. Phase 5 swaps the mock values for
/// WeatherService data; the display structure stays as-is.
struct WeatherWidget: DashboardWidget {
    var id: WidgetIdentifier { .weather }
    var columnSpan: Int { DashboardConfiguration.current.layoutMode.columnSpan(for: .weather) }
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
}
