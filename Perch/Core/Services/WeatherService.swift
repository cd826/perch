import CoreLocation
import Foundation
import WeatherKit

/// Everything the weather card renders, decoupled from WeatherKit
/// (SPEC §14.1, §16). `isFallback` marks demo data used when the
/// WeatherKit service is unreachable.
struct WeatherSnapshot: Equatable {
    struct HourEntry: Equatable, Identifiable {
        let id: Int
        let hour: String          // "12"
        let symbolName: String
        let temperature: Int      // °C
    }

    let city: String
    let temperature: Int
    let condition: String
    let symbolName: String
    let high: Int
    let low: Int
    let hourly: [HourEntry]
    let fetchedAt: Date
    let isFallback: Bool
}

/// WeatherService (SPEC §14, §17): WeatherKit behind this facade, a
/// 30-minute cache, refresh on demand/activation, and graceful
/// failure — the last good snapshot stays visible with its timestamp
/// (SPEC §22). If WeatherKit itself is unavailable (no capability /
/// signing) the card falls back to clearly-labelled demo data.
@MainActor
final class WeatherService: ObservableObject {
    static let shared = WeatherService()
    static let refreshInterval: TimeInterval = 30 * 60

    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var error: String?

    private let weatherService = WeatherKit.WeatherService()
    private var currentRequest: (location: CLLocation, city: String)?
    private var isLoading = false

    /// Fetches fresh data when the cache is older than the refresh
    /// interval or the target changed; `force` bypasses the interval.
    func refreshIfStale(location: CLLocation, city: String, force: Bool = false) {
        if !force, isLoading, currentRequest.map({ $0.city == city }) == true { return }
        if !force,
           let updated = lastUpdated,
           Date().timeIntervalSince(updated) < Self.refreshInterval,
           currentRequest.map({ $0.location.distance(from: location) < 1000 }) == true,
           currentRequest?.city == city {
            return  // cache still fresh and target unchanged
        }
        currentRequest = (location, city)
        isLoading = true
        Task {
            await load(location: location, city: city)
        }
    }

    private func load(location: CLLocation, city: String) async {
        do {
            let weather = try await withTimeout(seconds: 15) {
                try await self.weatherService.weather(for: location)
            }
            snapshot = Self.makeSnapshot(weather: weather, city: city)
            lastUpdated = Date()
            self.error = nil
        } catch {
            // SPEC §17/§22: keep the last good data, surface the error.
            self.error = Self.errorMessage(for: error)
            if snapshot == nil {
                snapshot = Self.demoSnapshot(city: city)
            }
        }
        isLoading = false
    }

    // MARK: - Snapshot assembly

    private static func makeSnapshot(weather: Weather, city: String) -> WeatherSnapshot {
        let celsius = UnitTemperature.celsius
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"

        let current = weather.currentWeather
        let currentTemperature = Int(current.temperature.converted(to: celsius).value.rounded())

        var high = currentTemperature
        var low = currentTemperature
        if let today = weather.dailyForecast.forecast.first {
            high = Int(today.highTemperature.converted(to: celsius).value.rounded())
            low = Int(today.lowTemperature.converted(to: celsius).value.rounded())
        }

        var hourly: [WeatherSnapshot.HourEntry] = []
        for (index, hour) in weather.hourlyForecast.forecast.prefix(6).enumerated() {
            let temperature = Int(hour.temperature.converted(to: celsius).value.rounded())
            let entry = WeatherSnapshot.HourEntry(
                id: index,
                hour: formatter.string(from: hour.date),
                symbolName: hour.symbolName,
                temperature: temperature
            )
            hourly.append(entry)
        }

        return WeatherSnapshot(
            city: city,
            temperature: currentTemperature,
            condition: conditionText(current.condition),
            symbolName: current.symbolName,
            high: high,
            low: low,
            hourly: hourly,
            fetchedAt: Date(),
            isFallback: false
        )
    }

    private static func conditionText(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .sunShowers: return "晴"
        case .mostlyClear: return "大致晴朗"
        case .partlyCloudy: return "局部多云"
        case .mostlyCloudy, .cloudy: return "多云"
        case .drizzle, .freezingDrizzle: return "毛毛雨"
        case .rain, .heavyRain, .freezingRain: return "雨"
        case .isolatedThunderstorms, .scatteredThunderstorms, .thunderstorms, .strongStorms: return "雷暴"
        case .snow, .heavySnow, .flurries, .sleet, .blowingSnow: return "雪"
        case .foggy: return "雾"
        case .haze, .blowingDust: return "霾"
        case .windy, .breezy: return "大风"
        case .hot: return "炎热"
        case .frigid: return "严寒"
        case .hail: return "冰雹"
        case .hurricane, .tropicalStorm: return "风暴"
        default: return condition.rawValue
        }
    }

    private static func errorMessage(for error: Error) -> String {
        let description = error.localizedDescription
        let lowered = description.lowercased()
        if lowered.contains("401") || lowered.contains("forbidden") || lowered.contains("unauthorized") {
            return "WeatherKit 服务未授权（需要在开发者账号中启用 WeatherKit）。"
        }
        return description
    }

    /// Demo data shaped like the SPEC §16 example, used only while
    /// WeatherKit is unavailable so the card stays meaningful.
    private static func demoSnapshot(city: String) -> WeatherSnapshot {
        let hours: [(String, String, Int)] = [
            ("12", "sun.max", 32), ("13", "cloud.sun", 32), ("14", "cloud", 33),
            ("15", "cloud", 31), ("16", "cloud", 29), ("17", "cloud.drizzle", 27),
        ]
        return WeatherSnapshot(
            city: city,
            temperature: 31,
            condition: "Mostly Clear",
            symbolName: "cloud.sun",
            high: 33,
            low: 26,
            hourly: hours.enumerated().map { index, entry in
                WeatherSnapshot.HourEntry(id: index, hour: entry.0, symbolName: entry.1, temperature: entry.2)
            },
            fetchedAt: Date(),
            isFallback: true
        )
    }
}
