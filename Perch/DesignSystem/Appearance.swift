import SwiftUI

/// Shared colors and surfaces for the dashboard (SPEC §18, §19).
enum Appearance {
    /// Hairline border that keeps cards visible against similar tones.
    static let cardBorder = Color.primary.opacity(0.08)
}

/// Full-window background of the dashboard: a soft, low-contrast
/// gradient that adapts to light/dark (SPEC §19 — avoid excessively
/// bright backgrounds; the app stays visible for long periods).
struct DashboardBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.11, green: 0.11, blue: 0.12),
                   Color(red: 0.07, green: 0.07, blue: 0.08)]
                : [Color(red: 0.96, green: 0.96, blue: 0.97),
                   Color(red: 0.90, green: 0.91, blue: 0.93)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
