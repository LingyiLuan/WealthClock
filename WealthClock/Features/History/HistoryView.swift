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
                Text(verbatim: "密押 · \(reading.omenPhrase)")
                    .font(.system(size: 10, design: .serif)).kerning(1.2)
                    .foregroundStyle(Tokens.cinnabar)
            }
            Spacer()
            if let age = reading.result?.age(.neutral) {
                Text(verbatim: "\(Int(age.rounded())) 岁")
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
    @State private var showBill = false

    var body: some View {
        List {
            if let result = reading.result {
                Section("三情景") {
                    ForEach(result.scenarios, id: \.kind) { scenario in
                        ledgerRow(scenarioName(scenario.kind), scenario.freedomAge.map { "\(Int($0.rounded())) 岁" } ?? "未达")
                    }
                }
                Section("归因(中性基准)") {
                    ForEach(result.attributions, id: \.key) { item in
                        ledgerRow(attributionName(item.key), item.deltaYears.map { String(format: "%+.1f 年", $0) } ?? "不可比")
                    }
                }
            }
            if let profile = reading.profile {
                Section("输入摘要") {
                    ledgerRow("年龄", "\(profile.age)")
                    ledgerRow("月收入", String(format: "%.0f %@", profile.monthlyIncome, profile.currencyCode))
                    ledgerRow("月支出", String(format: "%.0f", profile.monthlyExpense))
                    ledgerRow("可投资产", String(format: "%.0f", profile.investableAssets))
                    ledgerRow("交易习惯", profile.tradingHabit.label)
                }
                Section {
                    NavigationLink("重看揭晓") { RevealView(profile: profile) }
                    Button("查看汇票") { showBill = true }
                        .foregroundStyle(Tokens.ink)
                }
            }
            Section("密押") {
                Text(verbatim: "\(reading.ganzhi)流年 · \(reading.omenPhrase)")
                    .foregroundStyle(Tokens.cinnabar)
                    .font(.system(size: 13, design: .serif))
                Text(verbatim: reading.omenGloss)
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Tokens.inkSoft)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Tokens.paper.ignoresSafeArea())
        .navigationTitle(reading.date.formatted(date: .abbreviated, time: .omitted))
        .sheet(isPresented: $showBill) {
            if let profile = reading.profile { BillScreen(profile: profile) }
        }
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
        case "optimistic": return "乐观"
        case "pessimistic": return "悲观"
        default: return "中性"
        }
    }

    private func attributionName(_ key: String) -> String {
        switch key {
        case "trading": return "炒股修正"
        case "sideHustle": return "副业"
        case "literacy": return "素养"
        case "selfControl": return "自控力"
        default: return key
        }
    }
}
