import CoreLocation
import Foundation

/// Everything the weather card renders, decoupled from the backend
/// (SPEC §14.1, §16). Data comes from the free Open-Meteo API — no
/// key, no developer account required.
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
}

/// WeatherService (SPEC §14, §17): Open-Meteo behind this facade, a
/// 30-minute cache, refresh on demand/activation, and graceful
/// failure — the last good snapshot stays visible with its timestamp
/// (SPEC §22).
@MainActor
final class WeatherService: ObservableObject {
    static let shared = WeatherService()
    static let refreshInterval: TimeInterval = 30 * 60

    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var error: String?

    private var currentRequest: (location: CLLocation, city: String)?
    private var isLoading = false

    /// Bypasses the system proxy: Open-Meteo is directly reachable,
    /// while proxied requests can hang (observed on this machine).
    private static let directSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = [:]
        configuration.timeoutIntervalForRequest = 20
        return URLSession(configuration: configuration)
    }()

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
            let snapshot = try await withTimeout(seconds: 15) {
                try await Self.fetchOpenMeteo(location: location, city: city)
            }
            self.snapshot = snapshot
            lastUpdated = Date()
            self.error = nil
        } catch {
            // SPEC §17/§22: no fresh data — surface the error and let
            // the UI keep/replace whatever it showed before.
            self.error = "天气数据获取失败：\(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Open-Meteo

    private static func fetchOpenMeteo(location: CLLocation, city: String) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", location.coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "2"),
        ]

        let (data, response) = try await Self.directSession.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WeatherAPIError.badStatus(code)
        }
        let payload = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return try assemble(payload: payload, city: city)
    }

    private static func assemble(payload: OpenMeteoResponse, city: String) throws -> WeatherSnapshot {
        let parser = ISOHourParser()
        let now = Date()

        // Hourly strip: the next 6 entries starting at (or after) now.
        var hourly: [WeatherSnapshot.HourEntry] = []
        var started = false
        var taken = 0
        for (index, iso) in payload.hourly.time.enumerated()
        where taken < 6 && index < payload.hourly.temperature2m.count {
            guard let date = parser.date(iso) else { continue }
            if !started {
                if date >= now.addingTimeInterval(-1800) { started = true }
                else { continue }
            }
            let code = index < payload.hourly.weatherCode.count ? payload.hourly.weatherCode[index] : 0
            let temperature = index < payload.hourly.temperature2m.count
                ? Int(payload.hourly.temperature2m[index].rounded()) : 0
            let described = describe(code: code)
            hourly.append(WeatherSnapshot.HourEntry(
                id: index,
                hour: parser.hourLabel(iso),
                symbolName: described.symbol,
                temperature: temperature
            ))
            taken += 1
        }
        guard taken > 0 else {
            throw WeatherAPIError.missingData("逐小时预报为空")
        }
        let currentTemp = payload.current.temperature2m
        let currentCode = payload.current.weatherCode

        let currentDescribed = describe(code: currentCode)
        var high = Int(payload.daily.temperature2mMax.first?.rounded() ?? Double(currentTemp))
        var low = Int(payload.daily.temperature2mMin.first?.rounded() ?? Double(currentTemp))
        if high < low { swap(&high, &low) }

        return WeatherSnapshot(
            city: city,
            temperature: Int(currentTemp.rounded()),
            condition: currentDescribed.text,
            symbolName: currentDescribed.symbol,
            high: high,
            low: low,
            hourly: hourly,
            fetchedAt: Date()
        )
    }
}

enum WeatherAPIError: LocalizedError {
    case badStatus(Int)
    case missingData(String)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "服务返回状态码 \(code)"
        case .missingData(let detail): return detail
        }
    }
}

// MARK: - Open-Meteo payload

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature2m: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature2m: [Double]
        let weatherCode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }

    struct Daily: Decodable {
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]

        enum CodingKeys: String, CodingKey {
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
        }
    }

    let current: Current
    let hourly: Hourly
    let daily: Daily
}

/// Parses Open-Meteo's local-time ISO strings ("2026-09-15T17:00").
private struct ISOHourParser {
    private let formatter: DateFormatter

    init() {
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.isLenient = false
    }

    func date(_ iso: String) -> Date? {
        formatter.date(from: iso)
    }

    func hourLabel(_ iso: String) -> String {
        let parts = iso.split(separator: "T")
        guard parts.count == 2 else { return "--" }
        return String(parts[1].prefix(2))
    }
}

// MARK: - WMO weather codes → text + SF Symbol

func describe(code: Int) -> (text: String, symbol: String) {
    switch code {
    case 0: return ("晴", "sun.max")
    case 1: return ("大致晴朗", "sun.max")
    case 2: return ("局部多云", "cloud.sun")
    case 3: return ("阴", "cloud")
    case 45, 48: return ("雾", "cloud.fog")
    case 51, 53, 55: return ("毛毛雨", "cloud.drizzle")
    case 56, 57: return ("冻毛毛雨", "cloud.drizzle")
    case 61: return ("小雨", "cloud.rain")
    case 63: return ("中雨", "cloud.rain")
    case 65: return ("大雨", "cloud.heavyrain")
    case 66, 67: return ("冻雨", "cloud.rain")
    case 71, 73, 75, 77: return ("雪", "snow")
    case 80, 81, 82: return ("阵雨", "cloud.heavyrain")
    case 85, 86: return ("阵雪", "snow")
    case 95: return ("雷暴", "cloud.bolt.rain")
    case 96, 99: return ("雷暴伴冰雹", "cloud.bolt.rain")
    default: return ("未知", "cloud")
    }
}
