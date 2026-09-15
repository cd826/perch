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

    private let city = "Guangzhou"
    private let temperature = "31°"
    private let condition = "Mostly Clear"
    private let currentSymbol = "cloud.sun"
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

    /// Two-column layout, styled like the macOS weather widget:
    /// city and current temperature on the left, condition and range
    /// on the right, hourly strip along the bottom. Sized to fit the
    /// square row (176pt) without stretching it.
    private var wideLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(city)
                        .font(Typography.widgetTitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(temperature)
                        .font(Typography.temperatureLarge)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Image(systemName: currentSymbol)
                        .font(.system(size: 20))
                        .foregroundStyle(.tint)
                    Text(condition)
                        .font(Typography.body)
                        .lineLimit(1)
                    Text(dailyRange)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            Divider()
            hourlyStrip(itemCount: hourly.count)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// One-column layout for narrow cards: city, temperature beside
    /// the daily range (the condition line is dropped — it does not
    /// fit a 1-column card), then a shorter hourly strip.
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(city)
                .font(Typography.widgetTitle)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text(temperature)
                    .font(Typography.temperatureCompact)
                Spacer(minLength: Spacing.small)
                Text(dailyRange)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Divider()
            hourlyStrip(itemCount: 4)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func hourlyStrip(itemCount: Int) -> some View {
        HStack(spacing: Spacing.small) {
            ForEach(hourly.prefix(itemCount)) { item in
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
    }
}
