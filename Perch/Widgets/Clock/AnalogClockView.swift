import SwiftUI

/// Analog clock face styled after the macOS clock widget (SPEC §10):
/// a white dial with black numerals and minute ticks, bold black
/// hour/minute hands and an orange second hand with a tail. The
/// second hand sweeps smoothly; TimelineView(.animation) drives it
/// and SwiftUI stops it whenever the view is not on screen.
struct AnalogClockView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            ClockFace(date: timeline.date)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("模拟时钟")
                .accessibilityValue("当前时间 \(Self.timeText(date: timeline.date))")
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    static func timeText(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct ClockFace: View {
    let date: Date

    var body: some View {
        GeometryReader { proxy in
            let dim = min(proxy.size.width, proxy.size.height)
            let face = dim * 0.98
            let angles = handAngles(for: date)

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: face, height: face)
                    .shadow(color: .black.opacity(0.18), radius: face * 0.012, y: face * 0.006)
                    .overlay {
                        Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                    }

                ForEach(0..<60, id: \.self) { index in
                    let major = index.isMultiple(of: 5)
                    Capsule()
                        .fill(Color.black.opacity(major ? 0.8 : 0.45))
                        .frame(
                            width: max(face * (major ? 0.011 : 0.005), 1),
                            height: face * (major ? 0.045 : 0.03)
                        )
                        .offset(y: -face * 0.462)
                        .rotationEffect(.degrees(Double(index) * 6))
                }

                ForEach(1...12, id: \.self) { hour in
                    let radians = Double(hour) * 30 / 180 * .pi - .pi / 2
                    Text("\(hour)")
                        .font(.system(size: face * 0.142, weight: .medium))
                        .foregroundStyle(.black)
                        .offset(
                            x: cos(radians) * face * 0.325,
                            y: sin(radians) * face * 0.325
                        )
                }

                Hand(
                    length: face * 0.225, width: face * 0.05, tail: face * 0.02,
                    angle: angles.hour, color: .black
                )
                Hand(
                    length: face * 0.33, width: face * 0.04, tail: face * 0.03,
                    angle: angles.minute, color: .black
                )
                Hand(
                    length: face * 0.40, width: face * 0.013, tail: face * 0.11,
                    angle: angles.second, color: .orange
                )

                Circle()
                    .fill(Color.orange)
                    .frame(width: face * 0.062)
                Circle()
                    .fill(Color.white)
                    .frame(width: face * 0.026)
            }
            .frame(width: dim, height: dim)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

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
