import FreedomEngine
import SwiftUI

/// 沙盘状态:四个可拉动量 → Profile 映射(可测:apply 结果与直接构造一致)。
/// 沙盘是试算,不写入历史。
struct WhatIfState: Equatable {
    var savingsRatePercent: Int
    var tradingHabit: TradingHabit
    var hasSideHustle: Bool
    var investableAssets: Double

    init(from profile: Profile) {
        savingsRatePercent = profile.monthlyIncome > 0
            ? Int(((1 - profile.monthlyExpense / profile.monthlyIncome) * 100).rounded())
            : 0
        tradingHabit = profile.tradingHabit
        hasSideHustle = profile.hasSideHustle
        investableAssets = profile.investableAssets
    }

    /// 储蓄率以当前收入为基准反算月支出;其余字段原样覆盖。
    func apply(to profile: Profile) -> Profile {
        var modified = profile
        modified.monthlyExpense = profile.monthlyIncome * (1 - Double(savingsRatePercent) / 100)
        modified.tradingHabit = tradingHabit
        modified.hasSideHustle = hasSideHustle
        modified.investableAssets = investableAssets
        return modified
    }
}

/// 沙盘(付费功能):拉动储蓄率与习惯,实时看三情景年龄变化。引擎零改动,纯调用。
struct WhatIfPanel: View {
    let original: Profile
    let originalResult: FreedomResult
    @State private var state: WhatIfState

    init(original: Profile, originalResult: FreedomResult) {
        self.original = original
        self.originalResult = originalResult
        _state = State(initialValue: WhatIfState(from: original))
    }

    private var liveResult: FreedomResult { FreedomEngine.run(state.apply(to: original)) }
    private var isPristine: Bool { state == WhatIfState(from: original) }

    var body: some View {
        let result = liveResult
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("沙盘")
                    .font(.system(size: 13, design: .serif)).kerning(1.5)
                    .foregroundStyle(Tokens.ink)
                Text("试算,不入历史")
                    .font(.system(size: 9, design: .serif)).kerning(1)
                    .foregroundStyle(Tokens.inkSoft.opacity(0.7))
                Spacer()
                if !isPristine {
                    Button("恢复原始") { state = WhatIfState(from: original) }
                        .font(.system(size: 11, design: .serif)).kerning(1.2)
                        .foregroundStyle(Tokens.inkSoft)
                }
            }
            sliderRow
            habitRow
            HStack {
                Toggle(isOn: $state.hasSideHustle) {
                    Text("副业").font(.system(size: 12, design: .serif)).foregroundStyle(Tokens.ink)
                }
                .tint(Tokens.giltDeep)
                .frame(width: 110)
                Spacer()
                assetsField
            }
            resultRow(result)
        }
        .padding(12)
        .background(.white.opacity(0.33))
        .border(Tokens.gilt.opacity(0.6), width: 1)
    }

    private var sliderRow: some View {
        VStack(spacing: 2) {
            HStack {
                Text("储蓄率").font(.system(size: 12, design: .serif)).foregroundStyle(Tokens.inkSoft)
                Spacer()
                Text(verbatim: "\(state.savingsRatePercent)%")
                    .font(.system(size: 14, design: .monospaced)).foregroundStyle(Tokens.giltDeep)
            }
            Slider(
                value: Binding(
                    get: { Double(state.savingsRatePercent) },
                    set: { state.savingsRatePercent = Int($0.rounded()) }
                ),
                in: 0...80,
                step: 1
            )
            .tint(Tokens.giltDeep)
        }
    }

    private var habitRow: some View {
        HStack(spacing: 6) {
            ForEach(TradingHabit.allCases, id: \.self) { habit in
                Button {
                    state.tradingHabit = habit
                } label: {
                    Text(verbatim: habitShort(habit))
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(Tokens.ink)
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .background(state.tradingHabit == habit ? Tokens.gilt.opacity(0.15) : .clear)
                        .border(state.tradingHabit == habit ? Tokens.gilt : Tokens.ink.opacity(0.2), width: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var assetsField: some View {
        HStack(spacing: 6) {
            Text("资产").font(.system(size: 12, design: .serif)).foregroundStyle(Tokens.inkSoft)
            TextField("可投资资产", value: $state.investableAssets, format: .number.precision(.fractionLength(0)))
                .keyboardType(.decimalPad)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Tokens.ink)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
                .padding(.horizontal, 6)
                .frame(height: 30)
                .background(.white.opacity(0.4))
                .border(Tokens.ink.opacity(0.2), width: 1)
        }
    }

    private func resultRow(_ result: FreedomResult) -> some View {
        HStack(spacing: 10) {
            miniChip("乐观", .optimistic, result)
            miniChip("中性", .neutral, result)
            miniChip("悲观", .pessimistic, result)
        }
    }

    private func miniChip(_ title: String, _ kind: ScenarioKind, _ result: FreedomResult) -> some View {
        let live = result.scenario(kind)?.freedomAge
        let base = originalResult.scenario(kind)?.freedomAge
        let delta: Double? = {
            guard let live, let base else { return nil }
            return ((live - base) * 10).rounded() / 10
        }()
        return VStack(spacing: 2) {
            Text(verbatim: title)
                .font(.system(size: 10, design: .serif)).kerning(1.5)
                .foregroundStyle(Tokens.inkSoft)
            Text(verbatim: live.map { String(Int($0.rounded())) } ?? "未达")
                .font(.system(size: 18, design: .serif))
                .foregroundStyle(Tokens.ink)
            Text(verbatim: deltaText(delta))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle((delta ?? 0) <= 0 ? Tokens.verdigris : Tokens.cinnabar)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.white.opacity(0.4))
        .border(Tokens.ink.opacity(0.15), width: 1)
    }

    private func deltaText(_ delta: Double?) -> String {
        guard let delta else { return "—" }
        if delta == 0 { return "±0" }
        return delta < 0 ? "提前 \(String(format: "%.1f", -delta))" : "推迟 \(String(format: "%.1f", delta))"
    }

    private func habitShort(_ habit: TradingHabit) -> String {
        switch habit {
        case .indexOnly: return "定投"
        case .occasional: return "偶尔"
        case .weekly: return "每周"
        case .dayTrading: return "日内"
        }
    }
}
