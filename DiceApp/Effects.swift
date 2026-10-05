import SwiftUI

/// 擲出豹子時從畫面中央噴發的彩帶
struct ConfettiBurst: View {
    let trigger: Int

    private struct Piece {
        let vx, vy, spin, flip, width, height: Double
        let color: Color
    }

    @State private var start: Date?
    @State private var pieces: [Piece] = []

    private static let palette: [Color] = [
        Color(red: 1.0, green: 0.36, blue: 0.62), Color(red: 0.38, green: 0.96, blue: 1.0),
        Color(red: 1.0, green: 0.84, blue: 0.30), Color(red: 0.70, green: 0.45, blue: 1.0),
        Color(red: 0.45, green: 1.0, blue: 0.65), .white,
    ]

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let t = timeline.date.timeIntervalSince(start)
                context.opacity = max(0, 1 - pow(t / 2.8, 3))
                for piece in pieces {
                    var ctx = context
                    ctx.translateBy(
                        x: size.width * 0.5 + piece.vx * t,
                        y: size.height * 0.4 + piece.vy * t + 0.5 * 1100 * t * t
                    )
                    ctx.rotate(by: .radians(piece.spin * t))
                    ctx.scaleBy(x: cos(piece.flip * t), y: 1)
                    let rect = CGRect(x: -piece.width / 2, y: -piece.height / 2, width: piece.width, height: piece.height)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .task(id: trigger) {
            guard trigger > 0 else { return }
            pieces = (0..<140).map { _ in
                let angle = Double.random(in: -.pi * 0.95 ... -.pi * 0.05)
                let speed = Double.random(in: 450...1150)
                return Piece(
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    spin: .random(in: -12...12),
                    flip: .random(in: 4...14),
                    width: .random(in: 6...11),
                    height: .random(in: 9...16),
                    color: Self.palette.randomElement()!
                )
            }
            start = .now
            try? await Task.sleep(for: .seconds(3))
            start = nil
        }
    }
}

/// 斜向掃過的光帶
struct Shimmer: View {
    var period: Double = 2.6

    var body: some View {
        TimelineView(.animation) { timeline in
            let progress = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
            GeometryReader { proxy in
                let w = proxy.size.width
                LinearGradient(colors: [.clear, .white.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: w * 0.3)
                    .rotationEffect(.degrees(20))
                    .offset(x: -w * 0.4 + progress * w * 1.8)
                    .frame(maxHeight: .infinity)
            }
        }
        .allowsHitTesting(false)
    }
}

struct RollButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                Capsule().fill(LinearGradient(
                    colors: [Color(red: 1.0, green: 0.36, blue: 0.62), Color(red: 0.66, green: 0.30, blue: 1.0), Color(red: 0.22, green: 0.62, blue: 1.0)],
                    startPoint: .leading, endPoint: .trailing
                ))
            }
            .overlay { Shimmer().clipShape(Capsule()) }
            .overlay { Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 1) }
            .shadow(color: Color(red: 0.8, green: 0.3, blue: 1.0).opacity(0.65), radius: 22, y: 8)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(duration: 0.25, bounce: 0.5), value: configuration.isPressed)
    }
}
