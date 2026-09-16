import AppKit
import Combine
import CoreLocation
import Foundation

/// Presentation state for the weather card (SPEC §15–17, §22).
enum WeatherState: Equatable {
    case loading
    case needsLocationPermission    // automatic mode, CoreLocation denied/not yet granted
    case setupRequired              // manual mode with no city configured
    case failed(String, snapshot: WeatherSnapshot?)
    case loaded(WeatherSnapshot, staleNotice: String?)
}

/// LocationService + WeatherService → WeatherViewModel → WeatherWidget
/// (SPEC §29.3). Drives refreshes on launch, activation and when the
/// resolved location changes; caches otherwise (SPEC §17).
@MainActor
final class WeatherViewModel: ObservableObject {
    @Published private(set) var state: WeatherState = .loading

    private let locationService: LocationService
    private let weatherService: WeatherService
    private var cancellables: Set<AnyCancellable> = []
    private var recomputeScheduled = false
    private var refreshTimer: Timer?

    init(locationService: LocationService = .shared,
         weatherService: WeatherService = .shared) {
        self.locationService = locationService
        self.weatherService = weatherService

        func observe<P: Publisher>(_ publisher: P) -> AnyCancellable where P.Failure == Never {
            publisher.sink { [weak self] _ in self?.scheduleRecompute() }
        }
        cancellables.insert(observe(locationService.$state))
        cancellables.insert(observe(weatherService.$snapshot))
        cancellables.insert(observe(weatherService.$error))
        cancellables.insert(observe(weatherService.$lastUpdated))

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PerchWeatherRefreshRequested"), object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshNow() }
        }

        // SPEC §17: refresh periodically and when the application
        // becomes active. The dashboard is a resident app that runs
        // for days, so also re-check after system wake (data is stale
        // every morning otherwise). All paths funnel through
        // recompute → refreshIfStale, whose 30-minute cache keeps
        // actual network requests sparse (SPEC: no continuous
        // requests); a failed fetch leaves lastUpdated old, so the
        // next check retries on its own.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleRecompute() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleRecompute() }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleRecompute() }
        }

        locationService.resolve()
        scheduleRecompute()
    }

    /// @Published sinks fire during willSet, i.e. before the stored
    /// value updates — recomputing synchronously can read a torn mix
    /// of old/new state. Debouncing to the next tick guarantees the
    /// recompute sees the final, consistent values.
    private func scheduleRecompute() {
        guard !recomputeScheduled else { return }
        recomputeScheduled = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000)
            recomputeScheduled = false
            recompute()
        }
    }

    /// Activation hook + explicit retry (SPEC §17).
    func refreshNow() {
        locationService.resolve()
        if let location = locationService.location, case .resolved(let city) = locationService.state {
            weatherService.refreshIfStale(location: location, city: city, force: true)
        }
    }

    /// Called by the permission prompt on the card.
    func requestLocationAccess() {
        locationService.resolve()
    }

    private func recompute() {
        let weatherError = weatherService.error

        switch locationService.state {
        case .denied:
            state = .needsLocationPermission
            return
        case .idle:
            state = .setupRequired
            return
        case .locating:
            if weatherService.snapshot == nil {
                state = .loading
                return
            }
        case .failed(let message):
            state = .failed(message, snapshot: weatherService.snapshot)
            return
        case .resolved(let city):
            if let location = locationService.location {
                weatherService.refreshIfStale(location: location, city: city)
            }
        }

        if let snapshot = weatherService.snapshot {
            state = .loaded(snapshot, staleNotice: weatherError)
        } else if let weatherError {
            state = .failed(weatherError, snapshot: nil)
        } else {
            state = .loading
        }
    }
}
