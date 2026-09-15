import CoreLocation
import Foundation

/// How the weather card resolves "where am I" (SPEC §15).
enum WeatherLocationMode: String, CaseIterable {
    case automatic
    case manual

    var displayName: String {
        switch self {
        case .automatic: return "自动定位"
        case .manual: return "手动城市"
        }
    }
}

/// Where the weather request targets.
enum LocationState: Equatable {
    case idle                       // nothing configured yet
    case locating                   // resolving
    case denied                     // CoreLocation permission denied
    case resolved(city: String)
    case failed(String)
}

/// LocationService (SPEC §15): automatic location via CoreLocation +
/// reverse geocoding, or a manual city via forward geocoding. The
/// mode and city persist (SPEC §24); failures surface as states, the
/// app never crashes (SPEC §22).
@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published private(set) var mode: WeatherLocationMode
    @Published private(set) var manualCity: String
    @Published private(set) var state: LocationState = .idle

    /// Coordinate for the weather request, set once resolved.
    private(set) var location: CLLocation?

    private let manager = CLLocationManager()

    override private init() {
        let defaults = UserDefaults.standard
        mode = WeatherLocationMode(
            rawValue: defaults.string(forKey: ConfigurationStore.weatherLocationModeKey) ?? ""
        ) ?? .automatic
        manualCity = defaults.string(forKey: ConfigurationStore.weatherManualCityKey) ?? ""
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        resolve()
    }

    func setMode(_ newMode: WeatherLocationMode) {
        mode = newMode
        UserDefaults.standard.set(newMode.rawValue, forKey: ConfigurationStore.weatherLocationModeKey)
        resolve()
    }

    func setManualCity(_ city: String) {
        manualCity = city
        UserDefaults.standard.set(city, forKey: ConfigurationStore.weatherManualCityKey)
        if mode == .manual {
            resolve()
        }
    }

    /// Re-resolves from scratch (launch, activation, settings change).
    func resolve() {
        switch mode {
        case .automatic:
            resolveAutomatic()
        case .manual:
            geocode(city: manualCity)
        }
    }

    // MARK: - Automatic

    private func resolveAutomatic() {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            state = .denied
        case .notDetermined:
            state = .locating
            manager.requestWhenInUseAuthorization()
        default:
            state = .locating
            manager.requestLocation()
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        Task {
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await withTimeout(seconds: 15) {
                    try await geocoder.reverseGeocodeLocation(location)
                }
                let placemark = placemarks.first
                let city = placemark?.locality ?? placemark?.name ?? "当前位置"
                self.location = location
                state = .resolved(city: city)
            } catch {
                state = .failed("位置解析失败：\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Manual

    private func geocode(city: String) {
        guard !city.isEmpty else {
            location = nil
            state = .idle
            return
        }
        state = .locating
        Task {
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await withTimeout(seconds: 15) {
                    try await geocoder.geocodeAddressString(city)
                }
                guard let placemark = placemarks.first, let location = placemark.location else {
                    state = .failed("找不到城市「\(city)」")
                    return
                }
                self.location = location
                state = .resolved(city: placemark.locality ?? city)
            } catch {
                state = .failed("城市解析失败：\(error.localizedDescription)")
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                if mode == .automatic { manager.requestLocation() }
            case .denied, .restricted:
                state = .denied
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            guard let location = locations.last else { return }
            self.location = location
            reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            state = .failed("定位失败：\(error.localizedDescription)")
        }
    }
}
