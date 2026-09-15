import SwiftUI

/// Flip clock (SPEC §11): 24-hour HH:MM on split-flap cards, modeled
/// after classic web flip clocks (digitalclock.live): each card is a
/// static top/bottom pair plus two animated flaps — the old digit's
/// top half flips down over the center hinge while the new digit's
/// bottom half falls back into place, 0.6s ease-in-out. A 1-second
/// TimelineView is the only timer; apart from a change-triggered
/// flip the view stays idle.
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("翻页时钟")
            .accessibilityValue(String(format: "当前时间 %02d:%02d", hour, minute))
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

/// One split-flap card showing a single digit.
private struct FlipDigitView: View {
    let digit: String
    let size: CGSize

    // Static card halves. During a flip the upper half already shows
    // the new digit — it is covered by the front flap (old digit)
    // until that flap passes 90°.
    @State private var upper: String = ""
    @State private var lower: String = ""
    @State private var flapDigit: String = ""
    @State private var frontAngle: Double = 0
    @State private var backAngle: Double = 180
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Static card: top half on top, bottom half below.
            VStack(spacing: 0) {
                HalfDigit(text: upper, half: .top, cardSize: size)
                HalfDigit(text: lower, half: .bottom, cardSize: size)
            }
            if isAnimating {
                // New digit's bottom half, starting flipped up out of
                // view (180°) and falling back onto the lower half.
                HalfDigit(text: lower, half: .bottom, cardSize: size)
                    .rotation3DEffect(
                        .degrees(backAngle),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: 0.5
                    )
                    .frame(width: size.width, height: size.height, alignment: .bottom)
                // Old digit's top half, flipping down over the hinge.
                // Hidden past 90° like CSS backface-visibility: hidden.
                HalfDigit(text: flapDigit, half: .top, cardSize: size)
                    .rotation3DEffect(
                        .degrees(frontAngle),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.5
                    )
                    .opacity(frontAngle > 90 ? 0 : 1)
                    .frame(width: size.width, height: size.height, alignment: .top)
            }
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: digit) { _, newValue in
            guard !isAnimating else {
                upper = newValue
                lower = newValue
                return
            }
            guard newValue != upper else { return }
            isAnimating = true
            flapDigit = upper      // the flap carries the old digit away
            upper = newValue       // static top already shows the new digit
            lower = newValue       // static bottom switches immediately
            frontAngle = 0
            backAngle = 180
            withAnimation(.easeInOut(duration: 0.6)) {
                frontAngle = 180
                backAngle = 0
            } completion: {
                isAnimating = false
            }
        }
        .onAppear {
            upper = digit
            lower = digit
        }
    }
}

/// One half of a flap card: near-black background, the digit clipped
/// to this half, and the hairline seam on the top half's bottom edge.
private struct HalfDigit: View {
    let text: String
    let half: CardHalf
    let cardSize: CGSize

    private var halfHeight: CGFloat { cardSize.height / 2 }

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)
            Text(text)
                .font(.system(size: cardSize.height * 0.78, weight: .semibold))
                .foregroundStyle(Color(white: 0.8))
                .frame(width: cardSize.width, height: cardSize.height)
                .frame(width: cardSize.width, height: halfHeight,
                       alignment: half == .top ? .top : .bottom)
                .clipped()
            if half == .top {
                VStack {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                }
            }
        }
        .frame(width: cardSize.width, height: halfHeight)
    }
}

private enum CardHalf {
    case top, bottom
}

/// The breathing colon between the hour and minute card groups —
/// vivid orange (echoing the analog clock's second hand) so the dark
/// card row keeps a lively accent.
private struct FlipColonView: View {
    let active: Bool
    let size: CGSize

    var body: some View {
        VStack(spacing: size.height * 0.14) {
            dot
            dot
        }
        .frame(width: size.width)
        .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.05))
        .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.05).opacity(active ? 0.8 : 0), radius: size.width * 0.45)
        .opacity(active ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.5), value: active)
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
