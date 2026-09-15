import Foundation

/// Keys for the lightweight persisted preferences (SPEC §24).
/// V0.1 stores everything in UserDefaults via @AppStorage — no database.
enum ConfigurationStore {
    static let clockStyleKey = "perch.clockStyle"
    static let todoListIDKey = "perch.todoListID"
    static let weatherLocationModeKey = "perch.weatherLocationMode"
    static let weatherManualCityKey = "perch.weatherManualCity"
}
