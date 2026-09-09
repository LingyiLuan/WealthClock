import FreedomEngine
import SwiftData
import SwiftUI

/// 历史(BRIEF §6:免费;列表 + 详情,可重看揭晓与汇票)。
struct HistoryView: View {
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    var body: some View {
        NavigationStack {
            Group {
                if readings.isEmpty {
                    VStack(spacing: 10) {
                        Text("还没有测算记录")
                            .font(.system(size: 15, design: .serif)).kerning(2)
                            .foregroundStyle(Tokens.inkSoft)
                        Text("完成一次测算后,这里会替你记账。")
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(Tokens.inkSoft.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Tokens.paper.ignoresSafeArea())
                } else {
                    List(readings) { reading in
                        NavigationLink(destination: HistoryDetailView(reading: reading)) {
                            row(reading)
                        }
                        .listRowBackground(Color.white.opacity(0.33))
                    }
                    .scrollContentBackground(.hidden)
                    .background(Tokens.paper.ignoresSafeArea())
                }
            }
            .navigationTitle("历史")
        }
    }

    private func row(_ reading: Reading) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: reading.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(Tokens.ink)
                Text(verbatim: "密押 · \(reading.omenPhrase)")  // l10n-ignore
                    .font(.system(size: 10, design: .serif)).kerning(1.2)
                    .foregroundStyle(Tokens.cinnabar)
            }
            Spacer()
            if let age = reading.result?.age(.neutral) {
                Text(String(localized: "\(Int(age.rounded())) 岁"))
                    .font(.system(size: 20, design: .serif))
                    .foregroundStyle(Tokens.giltDeep)
            } else {
                Text("未达")
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Tokens.inkSoft)
            }
        }
    }
}

/// 详情:输入摘要 + 三情景 + 归因 + 密押;可重看揭晓与汇票。
struct HistoryDetailView: View {
    let reading: Reading
    @Query(sort: \Reading.date) private var allReadings: [Reading]
    @State private var showBill = false

    var body: some View {
        List {
            if StoreManager.shared.isUnlocked {
                yearComparisonSection
            }
            if let result = reading.result {
                Section("三情景") {
                    ForEach(result.scenarios, id: \.kind) { scenario in
                        ledgerRow(scenarioName(scenario.kind), scenario.freedomAge.map { String(localized: "\(Int($0.rounded())) 岁") } ?? String(localized: "未达"))
                    }
                }
                Section("归因(中性基准)") {
                    ForEach(result.attributions, id: \.key) { item in
                        ledgerRow(attributionName(item.key), item.deltaYears.map { String(localized: "\(String(format: "%+.1f", $0)) 年") } ?? String(localized: "不可比"))
                    }
                }
            }
            if let profile = reading.profile {
                Section("输入摘要") {
                    ledgerRow(String(localized: "年龄"), "\(profile.age)")
                    ledgerRow(String(localized: "月收入"), "\(profile.monthlyIncome.formatted(.number.precision(.fractionLength(0)))) \(profile.currencyCode)")
                    ledgerRow(String(localized: "月支出"), profile.monthlyExpense.formatted(.number.precision(.fractionLength(0))))
                    ledgerRow(String(localized: "可投资产"), profile.investableAssets.formatted(.number.precision(.fractionLength(0))))
                    ledgerRow(String(localized: "交易习惯"), profile.tradingHabit.label)
                }
                Section {
                    NavigationLink("重看揭晓") { RevealView(profile: profile, omenDate: reading.date) }
                    Button("查看汇票") { showBill = true }
                        .foregroundStyle(Tokens.ink)
                    if StoreManager.shared.isUnlocked {
                        NavigationLink("查看完整推演") { ScenariosView(profile: profile) }
                    }
                }
            }
            Section("密押") {
                Text(verbatim: "\(reading.ganzhi)流年 · \(reading.omenPhrase)")  // l10n-ignore
                    .foregroundStyle(Tokens.cinnabar)
                    .font(.system(size: 13, design: .serif))
                Text(verbatim: reading.omenGloss)  // l10n-ignore
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Tokens.inkSoft)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Tokens.paper.ignoresSafeArea())
        .navigationTitle(reading.date.formatted(date: .abbreviated, time: .omitted))
        .sheet(isPresented: $showBill) {
            if let profile = reading.profile { BillScreen(profile: profile, omenDate: reading.date) }
        }
    }

    /// 年度对比(BRIEF"年度对比",已解锁时显示)。
    @ViewBuilder private var yearComparisonSection: some View {
        Section("年度对比") {
            if let comparison = YearComparison.make(current: reading, among: allReadings) {
                HStack {
                    Text("中性自由年龄")
                        .font(.system(size: 13, design: .serif)).foregroundStyle(Tokens.inkSoft)
                    Spacer()
                    Text(verbatim: ageComparisonText(comparison))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle((comparison.ageDelta ?? 0) <= 0 ? Tokens.verdigris : Tokens.cinnabar)
                }
                ledgerRow(String(localized: "储蓄率"), "\(comparison.previousSavingsRate)% → \(comparison.currentSavingsRate)%")
                ledgerRow(
                    String(localized: "可投资资产"),
                    "\(comparison.previousAssets.formatted(.number.precision(.fractionLength(0)))) → \(comparison.currentAssets.formatted(.number.precision(.fractionLength(0))))"
                )
            } else {
                Text("明年再来测一次,这里会告诉你这一年值多少年。")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Tokens.inkSoft)
            }
        }
    }

    private func ageComparisonText(_ comparison: YearComparison) -> String {
        let previous = comparison.previousAge.map { String(Int($0.rounded())) } ?? String(localized: "未达")
        let current = comparison.currentAge.map { String(Int($0.rounded())) } ?? String(localized: "未达")
        guard let delta = comparison.ageDelta else { return "\(previous) → \(current)" }
        let verdict = delta <= 0 ? String(localized: "提前 \(String(format: "%.1f", -delta)) 年") : String(localized: "推迟 \(String(format: "%.1f", delta)) 年")
        return "\(previous) → \(current),\(verdict)"
    }

    private func ledgerRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(verbatim: key)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Tokens.inkSoft)
            Spacer()
            Text(verbatim: value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Tokens.ink)
        }
    }

    private func scenarioName(_ kind: String) -> String {
        switch kind {
        case "optimistic": return String(localized: "乐观")
        case "pessimistic": return String(localized: "悲观")
        default: return String(localized: "中性")
        }
    }

    private func attributionName(_ key: String) -> String {
        switch key {
        case "trading": return String(localized: "炒股修正")
        case "sideHustle": return String(localized: "副业")
        case "literacy": return String(localized: "素养")
        case "selfControl": return String(localized: "自控力")
        default: return key
        }
    }
}
