import SwiftUI

struct Roll: Identifiable, Equatable {
    let id = UUID()
    let first: Int
    let second: Int

    var total: Int { first + second }
    var isDouble: Bool { first == second }

    /// 特殊組合的徽章文字
    var badge: String? {
        switch (first, second) {
        case (6, 6): "雙六滿點！✨"
        case (1, 1): "蛇眼 🐍"
        case _ where isDouble: "豹子！🎉"
        case _ where total == 7: "幸運七 🍀"
        default: nil
        }
    }
}

struct ContentView: View {
    @State private var dice = [3, 4]
    @State private var isRolling = false
    @State private var rollCount = 0
    @State private var tick = 0
    @State private var lastRoll: Roll?
    @State private var history: [Roll] = []
    @State private var confetti = 0

    private var total: Int { dice.reduce(0, +) }

    var body: some View {
        ZStack {
            CosmicBackground()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 16)
                diceStage
                Spacer(minLength: 16)
                totalPanel
                historyRow
                    .padding(.top, 16)
                rollButton
                    .padding(.top, 20)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            ConfettiBurst(trigger: confetti)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: tick)
        .sensoryFeedback(.impact(weight: .heavy), trigger: lastRoll)
        .sensoryFeedback(.success, trigger: confetti)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 6) {
            Text("LUCKY  DICE")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(6)
                .foregroundStyle(.white.opacity(0.55))
            Text("幸運骰子")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(
                    colors: [DiePalette.rose.top, Color(red: 0.8, green: 0.6, blue: 1.0), DiePalette.aqua.top],
                    startPoint: .leading, endPoint: .trailing
                ))
                .shadow(color: DiePalette.rose.glow.opacity(0.5), radius: 16)
        }
        .padding(.top, 8)
    }

    private var diceStage: some View {
        HStack(spacing: 36) {
            DieView(value: dice[0], palette: .rose, rollTrigger: rollCount, spin: 720, axis: (0.5, 0.4, 1))
            DieView(value: dice[1], palette: .aqua, rollTrigger: rollCount, spin: -720, axis: (-0.4, 0.6, 1))
        }
        .padding(.vertical, 30)
        .contentShape(.rect)
        .onTapGesture(perform: roll)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("點兩下擲骰子")
    }

    private var totalPanel: some View {
        VStack(spacing: 2) {
            ZStack {
                if !isRolling, let badge = lastRoll?.badge {
                    Text(badge)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.88, blue: 0.4), Color(red: 1.0, green: 0.6, blue: 0.75)],
                            startPoint: .leading, endPoint: .trailing
                        )))
                        .shadow(color: .yellow.opacity(0.5), radius: 10)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                } else {
                    Text("總和")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.vertical, 6)
                        .transition(.opacity)
                }
            }

            Text("\(total)")
                .font(.system(size: 92, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(LinearGradient(
                    colors: [.white, Color(red: 1.0, green: 0.82, blue: 0.95)],
                    startPoint: .top, endPoint: .bottom
                ))
                .contentTransition(.numericText(value: Double(total)))
                .shadow(color: Color(red: 1.0, green: 0.4, blue: 0.85).opacity(0.6), radius: 22)
                .accessibilityLabel("總和 \(total)")

            HStack(spacing: 10) {
                equationChip(dice[0], color: DiePalette.rose.top)
                Text("+").foregroundStyle(.white.opacity(0.5))
                equationChip(dice[1], color: DiePalette.aqua.top)
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .contentTransition(.numericText())
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(.white.opacity(0.04)), in: .rect(cornerRadius: 32))
        .animation(.spring(duration: 0.4, bounce: 0.5), value: lastRoll)
        .animation(.spring(duration: 0.4, bounce: 0.5), value: isRolling)
    }

    private func equationChip(_ value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9).shadow(color: color, radius: 4)
            Text("\(value)").foregroundStyle(.white.opacity(0.85))
        }
    }

    private var historyRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.white.opacity(0.45))
            if history.isEmpty {
                Text("點骰子或按下方按鈕開始")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.45))
            }
            ForEach(history) { roll in
                Text("\(roll.total)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(roll.isDouble ? .black.opacity(0.8) : .white.opacity(0.85))
                    .frame(minWidth: 30, minHeight: 30)
                    .background {
                        Circle().fill(roll.isDouble
                            ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.88, blue: 0.4), Color(red: 1.0, green: 0.6, blue: 0.75)], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(.white.opacity(0.1)))
                    }
                    .opacity(roll.id == history.first?.id ? 1 : 0.75)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .frame(height: 32)
        .animation(.spring(duration: 0.4, bounce: 0.4), value: history)
    }

    private var rollButton: some View {
        Button(action: roll) {
            HStack(spacing: 10) {
                Image(systemName: "dice.fill")
                    .symbolEffect(.bounce, value: rollCount)
                Text(isRolling ? "滾動中…" : "擲骰子")
                    .contentTransition(.interpolate)
            }
        }
        .buttonStyle(RollButtonStyle())
        .disabled(isRolling)
        .animation(.easeInOut(duration: 0.2), value: isRolling)
    }

    // MARK: - Logic

    private func roll() {
        guard !isRolling else { return }
        isRolling = true
        rollCount += 1
        let result = Roll(first: .random(in: 1...6), second: .random(in: 1...6))

        Task {
            // 骰子在空中時快速亂跳，間隔逐漸拉長
            for step in 0..<12 {
                try? await Task.sleep(for: .milliseconds(40 + step * 8))
                withAnimation(.snappy(duration: 0.12)) {
                    dice = [.random(in: 1...6), .random(in: 1...6)]
                }
                tick += 1
            }

            withAnimation(.spring(duration: 0.45, bounce: 0.5)) {
                dice = [result.first, result.second]
                lastRoll = result
                history.insert(result, at: 0)
                if history.count > 7 { history.removeLast() }
                isRolling = false
            }
            if result.isDouble { confetti += 1 }
        }
    }
}

#Preview {
    ContentView()
}
