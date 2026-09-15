import SwiftUI

/// Flip clock (SPEC §11): 24-hour HH:MM on split cards. Digits run a
/// page-flip transition whenever their value changes (once per minute
/// for the minute digits). A 1-second TimelineView is the only timer;
/// apart from a change-triggered transition the view stays idle.
struct FlipClockView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let components = Calendar.current.dateComponents(
                [.hour, .minute, .second], from: timeline.date
            )
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0

            HStack(spacing: Spacing.small) {
                FlipDigitView(digit: digit(at: 0, of: hour))
                FlipDigitView(digit: digit(at: 1, of: hour))
                FlipColonView(active: (components.second ?? 0).isMultiple(of: 2))
                FlipDigitView(digit: digit(at: 0, of: minute))
                FlipDigitView(digit: digit(at: 1, of: minute))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func digit(at position: Int, of value: Int) -> String {
        let string = String(format: "%02d", value)
        let index = string.index(string.startIndex, offsetBy: position)
        return String(string[index])
    }
}

/// One flip card showing a single digit.
private struct FlipDigitView: View {
    let digit: String

    @State private var displayed: String = ""

    var body: some View {
        ZStack {
            Text(displayed)
                .font(Typography.flipDigit)
                .monospacedDigit()
                .transition(.flipPage)
                .id(displayed)
        }
        .modifier(FlipCardBackground())
        .aspectRatio(0.8, contentMode: .fit)
        .frame(maxHeight: .infinity)
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

/// The blinking colon between hours and minutes.
private struct FlipColonView: View {
    let active: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Circle().frame(width: 8, height: 8)
            Circle().frame(width: 8, height: 8)
        }
        .foregroundStyle(.tint)
        .opacity(active ? 1 : 0.25)
        .animation(.easeInOut(duration: 0.3), value: active)
    }
}

/// Card look shared by flip digits: material base, subtle split into
/// top/bottom halves, hairline seam and border.
private struct FlipCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                    VStack(spacing: 0) {
                        Color.primary.opacity(0.05)
                        Color.primary.opacity(0)
                    }
                    Rectangle()
                        .fill(Color.primary.opacity(0.18))
                        .frame(height: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1))
                }
            }
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
