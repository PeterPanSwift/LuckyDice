import SwiftUI

struct DiePalette {
    let top: Color
    let bottom: Color
    let glow: Color

    static let rose = DiePalette(
        top: Color(red: 1.0, green: 0.45, blue: 0.72),
        bottom: Color(red: 0.55, green: 0.16, blue: 0.95),
        glow: Color(red: 1.0, green: 0.32, blue: 0.80)
    )

    static let aqua = DiePalette(
        top: Color(red: 0.38, green: 0.96, blue: 1.0),
        bottom: Color(red: 0.16, green: 0.34, blue: 1.0),
        glow: Color(red: 0.22, green: 0.82, blue: 1.0)
    )
}

/// 一顆會跳起、翻滾、落地回彈的骰子（含地面陰影）
struct DieView: View {
    let value: Int
    let palette: DiePalette
    let rollTrigger: Int
    var size: CGFloat = 120
    /// 正值順時針、負值逆時針
    var spin: Double = 720
    var axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0.4, 0.5, 1)

    private struct Motion {
        var lift: CGFloat = 0
        var angle: Double = 0
        var scale: CGFloat = 1
        var squash: CGFloat = 1
    }

    var body: some View {
        KeyframeAnimator(initialValue: Motion(), trigger: rollTrigger) { motion in
            let height = min(1, -motion.lift / 130)
            ZStack(alignment: .bottom) {
                // 落在地面的光暈與陰影：骰子越高越小越淡
                Ellipse()
                    .fill(RadialGradient(
                        colors: [palette.glow.opacity(0.55), .black.opacity(0.35), .clear],
                        center: .center, startRadius: 0, endRadius: size * 0.5
                    ))
                    .frame(width: size * (1.1 - 0.45 * height), height: size * 0.22)
                    .opacity(1 - 0.6 * height)
                    .offset(y: size * 0.16)

                DieFace(value: value, palette: palette, size: size)
                    .scaleEffect(x: motion.scale * (2 - motion.squash), y: motion.scale * motion.squash, anchor: .bottom)
                    .rotation3DEffect(.degrees(motion.angle), axis: axis, perspective: 0.6)
                    .offset(y: motion.lift)
            }
        } keyframes: { _ in
            KeyframeTrack(\.lift) {
                CubicKeyframe(-130, duration: 0.32)
                CubicKeyframe(0, duration: 0.30)
                CubicKeyframe(-30, duration: 0.14)
                CubicKeyframe(0, duration: 0.14)
                CubicKeyframe(-7, duration: 0.08)
                CubicKeyframe(0, duration: 0.08)
            }
            KeyframeTrack(\.angle) {
                LinearKeyframe(spin * 0.8, duration: 0.62)
                CubicKeyframe(spin * 1.04, duration: 0.2)
                CubicKeyframe(spin * 0.99, duration: 0.14)
                CubicKeyframe(spin, duration: 0.12)
            }
            KeyframeTrack(\.scale) {
                CubicKeyframe(1.14, duration: 0.32)
                CubicKeyframe(1.0, duration: 0.30)
            }
            KeyframeTrack(\.squash) {
                CubicKeyframe(1.08, duration: 0.30)
                CubicKeyframe(1.0, duration: 0.30)
                CubicKeyframe(0.80, duration: 0.05)
                CubicKeyframe(1.08, duration: 0.12)
                CubicKeyframe(0.95, duration: 0.12)
                CubicKeyframe(1.0, duration: 0.16)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("骰子 \(value) 點")
    }
}

/// 骰子本體：糖果寶石般的漸層 + 高光 + 會彈出/縮回的點
struct DieFace: View {
    let value: Int
    let palette: DiePalette
    let size: CGFloat

    // 3x3 格子中，每個點數要亮起的位置（0...8，由左上往右下）
    private static let layouts: [Int: Set<Int>] = [
        1: [4],
        2: [0, 8],
        3: [0, 4, 8],
        4: [0, 2, 6, 8],
        5: [0, 2, 4, 6, 8],
        6: [0, 2, 3, 5, 6, 8],
    ]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
        let active = Self.layouts[value] ?? []
        let spacing = size * 0.27

        ZStack {
            shape.fill(LinearGradient(
                colors: [palette.top, palette.bottom],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))

            // 頂部高光
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.8, height: size * 0.42)
                .offset(x: -size * 0.05, y: -size * 0.26)
                .blur(radius: 1.5)

            // 底部反光
            Ellipse()
                .fill(palette.top.opacity(0.35))
                .frame(width: size * 0.6, height: size * 0.18)
                .offset(y: size * 0.4)
                .blur(radius: 8)

            ForEach(0..<9, id: \.self) { index in
                let isOn = active.contains(index)
                let isHero = value == 1 && index == 4
                Pip(palette: palette, diameter: size * 0.17)
                    .scaleEffect(isOn ? (isHero ? 1.55 : 1) : 0.01)
                    .opacity(isOn ? 1 : 0)
                    .offset(x: CGFloat(index % 3 - 1) * spacing, y: CGFloat(index / 3 - 1) * spacing)
            }

            shape.strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.85), .white.opacity(0.08), .black.opacity(0.25)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: size * 0.03
            )
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .shadow(color: palette.glow.opacity(0.75), radius: size * 0.22)
        .animation(.spring(duration: 0.28, bounce: 0.45), value: value)
    }
}

private struct Pip: View {
    let palette: DiePalette
    let diameter: CGFloat

    var body: some View {
        Circle()
            .fill(RadialGradient(
                colors: [.white, Color(white: 0.92), palette.top.opacity(0.9)],
                center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: diameter * 0.7
            ))
            .overlay(Circle().strokeBorder(palette.bottom.opacity(0.35), lineWidth: diameter * 0.08))
            .frame(width: diameter, height: diameter)
            .shadow(color: .white.opacity(0.9), radius: diameter * 0.3)
    }
}

#Preview {
    HStack(spacing: 30) {
        DieFace(value: 1, palette: .rose, size: 110)
        DieFace(value: 6, palette: .aqua, size: 110)
    }
    .padding(40)
    .background(.black)
}
