import FreedomEngine
import SwiftUI

/// 揭晓页(BRIEF §6 Reveal,设计稿 screens_v2B.html 第二屏)。
/// M3 先用 Profile.sample 硬编码;唯一动效:掷钱六次(180ms/次)→ 数字 1.3s ease-out 滚动。
@MainActor
struct RevealView: View {
    let profile: Profile
    /// 密押按此日期抽取(历史重看传存档日期,保证复看不变)。
    var omenDate: Date = .now
    /// 问卷上下文提供:重新测算(清空答案回第一题)。nil 时不显示。
    var onRestart: (() -> Void)?
    private let result: FreedomResult

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var coinFaces: [PixelCoin.Face] = [.yang, .yang, .yang]
    @State private var hexLines: [Bool] = []
    @State private var shownAge = 0.0
    @State private var revealed = false
    @State private var showBill = false
    @State private var showPaywall = false
    @State private var showScenarios = false
    @State private var store: StoreManager

    init(profile: Profile = .sample, omenDate: Date = .now, onRestart: (() -> Void)? = nil) {
        self.profile = profile
        self.omenDate = omenDate
        self.onRestart = onRestart
        result = FreedomEngine.run(profile)
        _store = State(initialValue: StoreManager.shared)
    }

    private var neutralAge: Double? { result.scenario(.neutral)?.freedomAge }

    private var omen: OmenEntry { OmenPicker.pick(for: profile, on: omenDate) }

    private var savingsRatePercent: Int {
        guard profile.monthlyIncome > 0 else { return 0 }
        return Int(((1 - profile.monthlyExpense / profile.monthlyIncome) * 100).rounded())
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Tokens.paper.ignoresSafeArea()
            seal
            VStack(spacing: 0) {
                Text("你的财务自由年龄")
                    .font(.system(size: 12, design: .serif)).kerning(5)
                    .foregroundStyle(Tokens.inkSoft)
                    .padding(.top, 24)
                headline
                coinRow
                scenarioChips
                HStack(spacing: 8) {
                    miyaDash
                    Text(verbatim: "密押 · \(OmenPicker.yearGanzhi())流年 · \(omen.phrase)")
                        .font(.system(size: 11, design: .serif)).kerning(2)
                        .foregroundStyle(Tokens.cinnabar)
                    miyaDash
                }
                .padding(.top, 16)
                Text(verbatim: omen.gloss)
                    .font(.system(size: 10, design: .serif)).kerning(1.2)
                    .foregroundStyle(Tokens.inkSoft)
                    .padding(.top, 4)
                Spacer(minLength: 12)
                buttons
                Text("本应用提供的是基于公开文献的情景测算与传统文化趣味解读,不构成投资、财务或法律建议。")
                    .font(.system(size: 10.5, design: .serif))
                    .foregroundStyle(Tokens.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
            .padding(.horizontal, Tokens.pageMargin)
        }
        .task {
            store.start()
            await playReveal()
        }
    }

    /// 大数字区:点阵年龄 + 岁 + 苏州码子行;未达时改为建议句(ADR-0003 / BRIEF §6)。
    @ViewBuilder private var headline: some View {
        if let age = neutralAge {
            let display = revealed ? Int(age.rounded()) : Int(shownAge)
            PixelDigits(text: String(display))
                .frame(height: 112)
                .padding(.top, 14)
            Text("岁")
                .font(.system(size: 15, design: .serif)).kerning(4.5)
                .foregroundStyle(Tokens.inkSoft)
                .padding(.top, 2)
            HStack(spacing: 6) {
                Text(verbatim: Suzhou.string(from: Int(age.rounded())))
                    .font(.system(size: 18, design: .serif))
                    .foregroundStyle(Tokens.giltDeep)
                Text(verbatim: "\(Suzhou.chineseUpper(Int(age.rounded()))) · 储蓄率 \(savingsRatePercent)%")
                    .font(.system(size: 13, design: .serif)).kerning(1.8)
                    .foregroundStyle(Tokens.ink)
            }
            .padding(.top, 10)
        } else {
            Text("未达")
                .font(.system(size: 64, design: .serif))
                .foregroundStyle(Tokens.ink)
                .padding(.top, 26)
            if let rate = FreedomEngine.requiredSavingsRate(profile, kind: .neutral, for: 65) {
                Text("把储蓄率提到 \(Int((rate * 100).rounded(.up)))% 可在 65 岁前自由")
                    .font(.system(size: 13, design: .serif)).kerning(1.8)
                    .foregroundStyle(Tokens.ink)
                    .padding(.top, 10)
            } else {
                Text("需提高储蓄率")
                    .font(.system(size: 13, design: .serif)).kerning(1.8)
                    .foregroundStyle(Tokens.inkSoft)
                    .padding(.top, 10)
            }
        }
    }

    private var coinRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    PixelCoin(face: coinFaces[index]).frame(width: 46, height: 46)
                }
            }
            HStack(spacing: 6) {
                ForEach(0..<6, id: \.self) { index in
                    yao(index < hexLines.count ? hexLines[index] : nil)
                }
            }
            Text(hexLines.count < 6 ? "六爻 · 第\(Suzhou.chineseUpper(hexLines.count + 1))爻落定" : "六爻 · 第六爻落定")
                .font(.system(size: 10, design: .serif)).kerning(2.6)
                .foregroundStyle(Tokens.inkSoft)
        }
        .padding(.top, 16)
    }

    /// 一根爻:阳实、阴断;未落定淡显。
    private func yao(_ yang: Bool?) -> some View {
        HStack(spacing: yang == false ? 4 : 0) {
            Rectangle().frame(width: yang == false ? 9 : 22, height: 3)
            if yang == false { Rectangle().frame(width: 9, height: 3) }
        }
        .foregroundStyle(yang == nil ? Tokens.inkSoft.opacity(0.25) : Tokens.ink)
    }

    private var scenarioChips: some View {
        HStack(spacing: 10) {
            chip("乐观", result.scenario(.optimistic)?.freedomAge, mid: false)
            chip("中性", neutralAge, mid: true)
            chip("悲观", result.scenario(.pessimistic)?.freedomAge, mid: false)
        }
        .padding(.top, 18)
    }

    private func chip(_ title: String, _ age: Double?, mid: Bool) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: title)
                .font(.system(size: 11, design: .serif)).kerning(2.2)
                .foregroundStyle(Tokens.inkSoft)
            Text(verbatim: age.map { String(Int($0.rounded())) } ?? "未达")
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(mid ? Tokens.giltDeep : Tokens.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(mid ? Tokens.gilt.opacity(0.1) : .white.opacity(0.33))
        .border(mid ? Tokens.gilt : Tokens.ink.opacity(0.2), width: 1)
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            Button {
                if store.isUnlocked { showScenarios = true } else { showPaywall = true }
            } label: {
                Text("查看完整推演")
                    .font(.system(size: 15, design: .serif)).kerning(3)
                    .foregroundStyle(Tokens.paper)
                    .frame(maxWidth: .infinity, minHeight: Tokens.primaryButtonHeight)
                    .background(Tokens.ink)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showScenarios) { scenariosDestination }
            Button { showBill = true } label: {
                Text("保存汇票")
                    .font(.system(size: 13, design: .serif)).kerning(2.4)
                    .foregroundStyle(Tokens.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .sheet(isPresented: $showBill) { BillScreen(profile: profile, omenDate: omenDate) }
            if let onRestart {
                Button(action: onRestart) {
                    Text("重新测算")
                        .font(.system(size: 12, design: .serif)).kerning(2)
                        .foregroundStyle(Tokens.inkSoft.opacity(0.8))
                        .frame(maxWidth: .infinity, minHeight: 24)
                }
            }
        }
    }

    /// 推演页在 M7 第三个 PR 落地;先用占位,避免付费后无处可去。
    private var scenariosDestination: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            Text("推演页 · 接入中")
                .font(.system(size: 15, design: .serif)).kerning(3)
                .foregroundStyle(Tokens.inkSoft)
        }
    }

    /// 密押行两侧短横线(设计稿 .miya::before/::after:22×1,朱砂 50%)。
    private var miyaDash: some View {
        Rectangle().fill(Tokens.cinnabar.opacity(0.5)).frame(width: 22, height: 1)
    }

    private var seal: some View {
        Text("財")
            .font(.system(size: 22, design: .serif))
            .foregroundStyle(Tokens.cinnabar)
            .frame(width: 40, height: 40)
            .border(Tokens.cinnabar, width: 2)
            .rotationEffect(.degrees(-5))
            .opacity(0.9)
            .padding(.top, 96)
            .padding(.trailing, 30)
    }

    /// 唯一动效:掷钱六次(180ms/次,随机阴阳)→ 数字 1.3s ease-out 滚动到结果。
    /// accessibilityReduceMotion 为真时直接显示终态。
    private func playReveal() async {
        let target = neutralAge ?? 0
        if reduceMotion {
            hexLines = (0..<6).map { _ in Bool.random() }
            shownAge = target
            revealed = true
            return
        }
        for _ in 0..<6 {
            try? await Task.sleep(for: .milliseconds(180))
            coinFaces = (0..<3).map { _ in Bool.random() ? PixelCoin.Face.yang : .yin }
            let yangCount = coinFaces.filter { $0 == .yang }.count
            hexLines.append(yangCount >= 2)
        }
        let start = Double(profile.age)
        let steps = 32
        for step in 1...steps {
            try? await Task.sleep(for: .milliseconds(1300 / steps))
            let t = Double(step) / Double(steps)
            let eased = 1 - pow(1 - t, 3)  // ease-out cubic
            shownAge = start + (target - start) * eased
        }
        revealed = true
    }
}

#Preview { RevealView() }
