import Charts
import FreedomEngine
import SwiftUI

/// 推演页(付费,BRIEF §6 Scenarios,设计稿第三屏):三曲线 + 自由线 + 账目 + 归因。
struct ScenariosView: View {
    let profile: Profile
    private let result: FreedomResult
    private let series: [(kind: ScenarioKind, points: [TrajectoryPoint])]

    init(profile: Profile) {
        self.profile = profile
        result = FreedomEngine.run(profile)
        series = ScenarioKind.allCases.map { ($0, FreedomEngine.trajectory(profile, kind: $0)) }
    }

    private func color(_ kind: ScenarioKind) -> Color {
        switch kind {
        case .optimistic: return Tokens.gilt
        case .neutral: return Tokens.ink
        case .pessimistic: return Tokens.verdigris
        }
    }

    private func name(_ kind: ScenarioKind) -> String {
        switch kind {
        case .optimistic: return String(localized: "乐观")
        case .neutral: return String(localized: "中性")
        case .pessimistic: return String(localized: "悲观")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("推演")
                    .font(.system(size: 22, design: .serif).weight(.medium)).kerning(1)
                    .foregroundStyle(Tokens.ink)
                    .padding(.top, 20)
                Text("资产轨迹 · 自由线 · 三情景")
                    .font(.system(size: 10.5, design: .monospaced)).kerning(1)
                    .foregroundStyle(Tokens.inkSoft)
                    .padding(.top, 6)
                WhatIfPanel(original: profile, originalResult: result)
                    .padding(.top, 14)
                legend.padding(.top, 14)
                chart
                    .frame(height: 230)
                    .padding(10)
                    .background(.white.opacity(0.27))
                    .border(Tokens.rule, width: 1)
                    .padding(.top, 6)
                ledger.padding(.top, 16)
                attributionList.padding(.top, 18)
                Text("情景测算,非投资建议;密押为传统文化趣味解读,不参与计算。")
                    .font(.system(size: 10.5, design: .serif))
                    .foregroundStyle(Tokens.inkSoft)
                    .padding(.vertical, 18)
            }
            .padding(.horizontal, Tokens.pageMargin)
        }
        .background(Tokens.paper.ignoresSafeArea())
    }

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(ScenarioKind.allCases, id: \.self) { kind in
                HStack(spacing: 5) {
                    Rectangle().fill(color(kind)).frame(width: 14, height: 2)
                    Text(verbatim: name(kind))
                        .font(.system(size: 10, design: .serif)).kerning(1.2)
                        .foregroundStyle(Tokens.inkSoft)
                }
            }
            HStack(spacing: 5) {
                Rectangle().fill(Tokens.cinnabar).frame(width: 14, height: 1)
                Text("自由线")
                    .font(.system(size: 10, design: .serif)).kerning(1.2)
                    .foregroundStyle(Tokens.inkSoft)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(series, id: \.kind) { item in
                ForEach(item.points, id: \.age) { point in
                    LineMark(
                        x: .value("年龄", point.age),
                        y: .value("资产", point.assets),
                        series: .value("情景", item.kind.rawValue)
                    )
                    .foregroundStyle(color(item.kind))
                    .lineStyle(StrokeStyle(lineWidth: 1.6))
                }
                if let crossing = item.points.last, crossing.assets >= crossing.freedomLine {
                    PointMark(x: .value("年龄", crossing.age), y: .value("资产", crossing.assets))
                        .symbol { PixelCoin(face: .yang).frame(width: 13, height: 13) }
                }
            }
            if let line = result.scenario(.neutral)?.freedomLine {
                RuleMark(y: .value("自由线", line))
                    .foregroundStyle(Tokens.cinnabar)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Tokens.rule)
                AxisTick().foregroundStyle(Tokens.inkSoft)
                AxisValueLabel().font(.system(size: 9, design: .monospaced)).foregroundStyle(Tokens.inkSoft)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Tokens.rule)
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(verbatim: amount.formatted(.number.notation(.compactName).precision(.significantDigits(3))))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Tokens.inkSoft)
                    }
                }
            }
        }
    }

    /// 账目四行(设计稿 .ledger)。
    private var ledger: some View {
        VStack(spacing: 0) {
            ledgerRow(String(localized: "月收入"), "\(profile.monthlyIncome.formatted(.number.precision(.fractionLength(0)))) \(profile.currencyCode)", gilt: false)
            ledgerRow(String(localized: "月支出(不含房贷)"), profile.monthlyExpense.formatted(.number.precision(.fractionLength(0))), gilt: false)
            ledgerRow(String(localized: "可投资资产"), profile.investableAssets.formatted(.number.precision(.fractionLength(0))), gilt: false)
            ledgerRow(String(localized: "自由线(中性)"), (result.scenario(.neutral)?.freedomLine ?? 0).formatted(.number.precision(.fractionLength(0))), gilt: true)
        }
    }

    private func ledgerRow(_ key: String, _ value: String, gilt: Bool) -> some View {
        HStack {
            Text(verbatim: key)
                .font(.system(size: 13, design: .serif)).kerning(0.8)
                .foregroundStyle(Tokens.inkSoft)
            Spacer()
            Text(verbatim: value)
                .font(.system(size: 13.5, design: .monospaced))
                .foregroundStyle(gilt ? Tokens.giltDeep : Tokens.ink)
        }
        .frame(minHeight: Tokens.ledgerRowHeight)
        .overlay(alignment: .bottom) { Rectangle().fill(Tokens.rule).frame(height: 1) }
    }

    /// 归因列表:每项一行,展开显示依据(设计稿要求)。
    private var attributionList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("归因(中性基准)")
                .font(.system(size: 13, design: .serif)).kerning(1.5)
                .foregroundStyle(Tokens.ink)
            ForEach(result.attributions, id: \.key) { item in
                DisclosureGroup {
                    Text(verbatim: "依据:\(item.basis)")
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(Tokens.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } label: {
                    HStack {
                        Text(verbatim: attributionName(item.key))
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(Tokens.ink)
                        Spacer()
                        Text(verbatim: item.deltaYears.map { String(localized: "\(String(format: "%+.1f", $0)) 年") } ?? String(localized: "不可比"))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle((item.deltaYears ?? 0) > 0 ? Tokens.cinnabar : Tokens.inkSoft)
                    }
                }
                .tint(Tokens.inkSoft)
            }
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
