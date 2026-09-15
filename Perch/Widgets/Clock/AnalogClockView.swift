import SwiftUI

/// Analog clock face (SPEC §10): hour/minute/second hands plus 12
/// hour markers on a minimal circular face that scales with the card.
/// The second hand sweeps smoothly; TimelineView(.animation) drives
/// it and SwiftUI stops it whenever the view is not on screen.
struct AnalogClockView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            ClockFace(date: timeline.date)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ClockFace: View {
    let date: Date

    var body: some View {
        GeometryReader { proxy in
            let dim = min(proxy.size.width, proxy.size.height)
            let angles = handAngles(for: date)

            ZStack {
                Circle()
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: max(dim * 0.012, 1.5))

                ForEach(0..<12, id: \.self) { index in
                    let major = index.isMultiple(of: 3)
                    Capsule()
                        .frame(
                            width: max(dim * (major ? 0.018 : 0.009), 1.5),
                            height: dim * (major ? 0.075 : 0.045)
                        )
                        .foregroundStyle(.secondary.opacity(major ? 1 : 0.6))
                        .offset(y: -dim * 0.425)
                        .rotationEffect(.degrees(Double(index) * 30))
                }

                Hand(
                    length: dim * 0.24, width: dim * 0.042, tail: dim * 0.04,
                    angle: angles.hour, color: .primary
                )
                Hand(
                    length: dim * 0.36, width: dim * 0.030, tail: dim * 0.06,
                    angle: angles.minute, color: .primary
                )
                Hand(
                    length: dim * 0.40, width: dim * 0.012, tail: dim * 0.10,
                    angle: angles.second, color: .accentColor
                )

                Circle()
                    .frame(width: dim * 0.045)
                    .foregroundStyle(.tint)
                Circle()
                    .frame(width: dim * 0.018)
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
            }
            .frame(width: dim, height: dim)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    private func handAngles(for date: Date) -> (hour: Double, minute: Double, second: Double) {
        let components = Calendar.current.dateComponents(
            [.hour, .minute, .second, .nanosecond], from: date
        )
        let second = Double(components.second ?? 0)
            + Double(components.nanosecond ?? 0) / 1_000_000_000
        let minute = Double(components.minute ?? 0) + second / 60
        let hour = Double((components.hour ?? 0) % 12) + minute / 60
        return (hour * 30, minute * 6, second * 6)
    }
}

/// A clock hand: a capsule pivoting around the face center, reaching
/// `length` forward and `tail` behind the pivot.
private struct Hand: View {
    let length: CGFloat
    let width: CGFloat
    let tail: CGFloat
    let angle: Double
    let color: Color

    var body: some View {
        Capsule()
            .frame(width: width, height: length + tail)
            .offset(y: -(length - tail) / 2)
            .rotationEffect(.degrees(angle))
            .foregroundStyle(color)
    }
}
