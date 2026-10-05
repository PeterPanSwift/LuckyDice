import SwiftUI

/// 會緩慢流動的極光網格漸層 + 閃爍星空
struct CosmicBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                MeshGradient(width: 3, height: 3, points: Self.points(at: t), colors: Self.colors)
                Starfield(time: t)
            }
        }
        .ignoresSafeArea()
    }

    private static let colors: [Color] = [
        Color(red: 0.05, green: 0.02, blue: 0.16), Color(red: 0.22, green: 0.05, blue: 0.42), Color(red: 0.04, green: 0.05, blue: 0.22),
        Color(red: 0.38, green: 0.05, blue: 0.46), Color(red: 0.10, green: 0.07, blue: 0.34), Color(red: 0.02, green: 0.26, blue: 0.42),
        Color(red: 0.03, green: 0.02, blue: 0.10), Color(red: 0.16, green: 0.03, blue: 0.32), Color(red: 0.02, green: 0.05, blue: 0.14),
    ]

    private static func points(at t: Double) -> [SIMD2<Float>] {
        let s = Float(sin(t * 0.45))
        let c = Float(cos(t * 0.37))
        return [
            [0, 0], [0.5 + 0.2 * s, 0], [1, 0],
            [0, 0.5 + 0.15 * c], [0.5 + 0.18 * c, 0.5 + 0.15 * s], [1, 0.5 - 0.15 * s],
            [0, 1], [0.5 - 0.2 * c, 1], [1, 1],
        ]
    }
}

private struct Starfield: View {
    let time: Double

    private struct Star {
        let x, y, radius, speed, phase: Double
    }

    private static let stars: [Star] = (0..<90).map { _ in
        Star(
            x: .random(in: 0...1),
            y: .random(in: 0...1),
            radius: .random(in: 0.4...1.6),
            speed: .random(in: 0.6...2.2),
            phase: .random(in: 0...(2 * .pi))
        )
    }

    var body: some View {
        Canvas { context, size in
            for star in Self.stars {
                let twinkle = 0.25 + 0.75 * abs(sin(time * star.speed + star.phase))
                let rect = CGRect(
                    x: star.x * size.width - star.radius,
                    y: star.y * size.height - star.radius,
                    width: star.radius * 2,
                    height: star.radius * 2
                )
                context.opacity = twinkle
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
    }
}
