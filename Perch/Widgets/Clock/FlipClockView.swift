import SwiftUI

/// Flip clock (SPEC §11): 24-hour HH:MM on split-flap cards styled
/// after the classic flip clock — near-black cards, oversized digits
/// and a center seam. Card size and font scale with the card; digits
/// flip when their value changes (once per minute for the minute
/// digits). A 1-second TimelineView is the only timer; apart from a
/// change-triggered transition the view stays idle.
struct FlipClockView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let components = Calendar.current.dateComponents(
                [.hour, .minute, .second], from: timeline.date
            )
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0

            GeometryReader { geo in
                let metrics = FlipLayoutMetrics(width: geo.size.width, height: geo.size.height)
                HStack(spacing: metrics.gap) {
                    FlipDigitView(digit: digit(at: 0, of: hour), size: metrics.cardSize)
                    FlipDigitView(digit: digit(at: 1, of: hour), size: metrics.cardSize)
                    FlipColonView(active: (components.second ?? 0).isMultiple(of: 2), size: metrics.colonSize)
                    FlipDigitView(digit: digit(at: 0, of: minute), size: metrics.cardSize)
                    FlipDigitView(digit: digit(at: 1, of: minute), size: metrics.cardSize)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private func digit(at position: Int, of value: Int) -> String {
        let string = String(format: "%02d", value)
        let index = string.index(string.startIndex, offsetBy: position)
        return String(string[index])
    }
}

/// Shared geometry for one flip-clock row: four digit cards plus a
/// colon, all derived from the available width and height.
private struct FlipLayoutMetrics {
    let cardSize: CGSize
    let colonSize: CGSize
    let gap: CGFloat

    init(width: CGFloat, height: CGFloat) {
        gap = max(width * 0.018, 8)
        let colonWidth = max(width * 0.028, 12)
        // Row structure: card card [colon] card card → 4 gaps.
        let cardWidth = (width - 4 * gap - colonWidth) / 4
        let cardHeight = min(height, cardWidth / 0.78)
        cardSize = CGSize(width: cardWidth, height: cardHeight)
        colonSize = CGSize(width: colonWidth, height: cardHeight)
    }
}

/// One flip card showing a single digit, Fliqlo-style: near-black
/// card, oversized light digit, hairline center seam, no border.
private struct FlipDigitView: View {
    let digit: String
    let size: CGSize

    @State private var displayed: String = ""

    var body: some View {
        ZStack {
            Text(displayed)
                .font(.system(size: size.height * 0.72, weight: .semibold))
                .foregroundStyle(Color(white: 0.84))
                .transition(.flipPage)
                .id(displayed)
        }
        .frame(width: size.width, height: size.height)
        .background {
            ZStack {
                VStack(spacing: 0) {
                    Color(red: 0.145, green: 0.145, blue: 0.155)
                    Color(red: 0.105, green: 0.105, blue: 0.115)
                }
                Rectangle()
                    .fill(Color.white.opacity(0.09))
                    .frame(height: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: max(size.height * 0.045, 6), style: .continuous))
        }
        .onChange(of: digit) { _, newValue in
            guard newValue != displayed else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                displayed = newValue
            }
        }
        .onAppear {
            displayed = digit
        }
    }
}

/// The blinking colon between the hour and minute card groups.
private struct FlipColonView: View {
    let active: Bool
    let size: CGSize

    var body: some View {
        VStack(spacing: size.height * 0.14) {
            dot
            dot
        }
        .frame(width: size.width)
        .foregroundStyle(Color(white: 0.42))
        .opacity(active ? 1 : 0.3)
        .animation(.easeInOut(duration: 0.3), value: active)
    }

    private var dot: some View {
        SwiftUI.Circle()
            .frame(width: dotDiameter)
            .frame(height: dotDiameter)
    }

    private var dotDiameter: CGFloat {
        max(size.width * 0.55, 5)
    }
}

/// Page-flip transition: an incoming digit falls from the top hinge
/// while the outgoing one tips away over the bottom hinge.
private extension AnyTransition {
    static var flipPage: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: FlipPageModifier(angle: -90, anchor: .top),
                identity: FlipPageModifier(angle: 0, anchor: .top)
            ),
            removal: .modifier(
                active: FlipPageModifier(angle: 90, anchor: .bottom),
                identity: FlipPageModifier(angle: 0, anchor: .bottom)
            )
        )
    }
}

private struct FlipPageModifier: ViewModifier {
    let angle: Double
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 1, y: 0, z: 0),
                anchor: anchor,
                perspective: 0.6
            )
            .opacity(max(0, 1 - abs(angle) / 90))
    }
}
