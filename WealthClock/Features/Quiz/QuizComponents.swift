import FreedomEngine
import SwiftUI

// MARK: - 选项行(设计稿 .opt:左像素铜钱 + 文案,右修正值;选中 gilt 边框)

struct ChoiceRow: View {
    let label: String
    var detail: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                PixelCoin(face: .yang).frame(width: 18, height: 18)
                    .opacity(selected ? 1 : 0.45)
                Text(verbatim: label)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Tokens.ink)
                Spacer()
                if let detail {
                    Text(verbatim: detail)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(selected ? Tokens.cinnabar : Tokens.inkSoft)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 46)
            .background(selected ? Tokens.gilt.opacity(0.1) : .white.opacity(0.33))
            .border(selected ? Tokens.gilt : Tokens.ink.opacity(0.2), width: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 数字输入(币种前缀 + 十进制键盘;校验在 QuizDraft.isAnswered)

struct MoneyField: View {
    let prefix: String
    let placeholder: String
    @Binding var value: Double?
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(verbatim: prefix)
                .font(.system(size: 18, design: .monospaced))
                .foregroundStyle(Tokens.giltDeep)
            TextField(placeholder, value: $value, format: .number.precision(.fractionLength(0)))
                .keyboardType(.decimalPad)
                .focused($focused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("完成") { focused = false }
                    }
                }
                .font(.system(size: 22, design: .monospaced))
                .foregroundStyle(Tokens.ink)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 54)
        .background(.white.opacity(0.33))
        .border(Tokens.ink.opacity(0.2), width: 1)
    }
}

// MARK: - 滚轮

struct WheelRow: View {
    let title: String
    let range: ClosedRange<Int>
    let unit: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: title)
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Tokens.inkSoft)
            Picker(title, selection: $value) {
                ForEach(Array(range), id: \.self) { number in
                    Text(verbatim: "\(number) \(unit)")
                        .font(.system(size: 18, design: .monospaced))
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 108)
            .clipped()
        }
    }
}

// MARK: - 素养题:即答即评(BRIEF §3.7)

struct LiteracyStepView: View {
    let question: LiteracyQuestion
    var draft: QuizDraft

    private var answer: Int? { draft.literacyAnswers[question.id] }

    var body: some View {
        @Bindable var draft = draft
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                ChoiceRow(
                    label: option,
                    detail: detail(for: index),
                    selected: answer == index
                ) {
                    if answer == nil { draft.literacyAnswers[question.id] = index }
                }
            }
            if let answer {
                Text(verbatim: (answer == question.correctIndex ? "答对了。" : "不对。") + question.explanation)
                    .font(.system(size: 12, design: .serif))
                    .lineSpacing(5)
                    .foregroundStyle(answer == question.correctIndex ? Tokens.verdigris : Tokens.cinnabar)
                    .padding(.top, 6)
            }
            Text("以首次作答计分")
                .font(.system(size: 10, design: .serif)).kerning(1.5)
                .foregroundStyle(Tokens.inkSoft.opacity(0.7))
                .padding(.top, 2)
        }
    }

    private func detail(for index: Int) -> String? {
        guard let answer else { return nil }
        if index == question.correctIndex { return "✓" }
        return index == answer ? "✕" : nil
    }
}

// MARK: - 题面分发(替换骨架占位)

struct QuizStepContent: View {
    let step: QuizStep
    var draft: QuizDraft

    var body: some View {
        @Bindable var draft = draft
        VStack(alignment: .leading, spacing: 10) {
            switch step {
            case .age:
                WheelRow(title: "年龄", range: 18...70, unit: "岁", value: $draft.age)
            case .region:
                ForEach(RegionChoice.allCases) { choice in
                    ChoiceRow(label: choice.label, selected: draft.regionChoice == choice) {
                        draft.regionChoice = choice
                    }
                }
            case .income:
                MoneyField(prefix: currencySymbol, placeholder: "税后月收入", value: $draft.monthlyIncome)
            case .expense:
                MoneyField(prefix: currencySymbol, placeholder: "月支出", value: $draft.monthlyExpense)
            case .assets:
                MoneyField(prefix: currencySymbol, placeholder: "可投资资产", value: $draft.investableAssets)
            case .mortgage:
                MoneyField(prefix: currencySymbol, placeholder: "每月月供", value: $draft.mortgageMonthly)
                WheelRow(title: "剩余年数", range: 0...40, unit: "年", value: $draft.mortgageYearsLeft)
            case .industryExperience:
                ForEach(Industry.allCases, id: \.self) { industry in
                    ChoiceRow(label: industry.label, selected: draft.industry == industry) {
                        draft.industry = industry
                    }
                }
                WheelRow(title: "工作年限", range: 0...40, unit: "年", value: $draft.yearsExperience)
            case .education:
                ForEach(Education.allCases, id: \.self) { education in
                    ChoiceRow(label: education.label, selected: draft.education == education) {
                        draft.education = education
                    }
                }
            case .trading:
                ForEach(TradingHabit.allCases, id: \.self) { habit in
                    ChoiceRow(label: habit.label, detail: draft.tradingDeltaText(habit), selected: draft.tradingHabit == habit) {
                        draft.tradingHabit = habit
                    }
                }
                Text("账户规模呢?(折合人民币)")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(Tokens.inkSoft)
                    .padding(.top, 8)
                ForEach(AccountTier.allCases, id: \.self) { tier in
                    ChoiceRow(label: tier.label, selected: draft.accountTier == tier) {
                        draft.accountTier = tier
                    }
                }
            case .sideHustle:
                ChoiceRow(label: "有", selected: draft.hasSideHustle == true) { draft.hasSideHustle = true }
                ChoiceRow(label: "没有", selected: draft.hasSideHustle == false) { draft.hasSideHustle = false }
            case .literacy(let index):
                LiteracyStepView(question: Literacy.questions[index], draft: draft)
            case .selfControl:
                selfControlSlider
            case .birthDate:
                Toggle(isOn: Binding(
                    get: { draft.birthDate != nil },
                    set: { draft.birthDate = $0 ? Date(timeIntervalSince1970: 631_152_000) : nil }
                )) {
                    Text(draft.birthDate == nil ? "不填(汇票用朱砂色系)" : "填写出生日期")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Tokens.ink)
                }
                .tint(Tokens.giltDeep)
                if draft.birthDate != nil {
                    DatePicker(
                        "出生日期",
                        selection: Binding(
                            get: { draft.birthDate ?? Date(timeIntervalSince1970: 631_152_000) },
                            set: { draft.birthDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "zh-Hans"))
                }
            }
        }
    }

    private var currencySymbol: String { draft.regionChoice?.currencySymbol ?? "¥" }

    private var selfControlSlider: some View {
        @Bindable var draft = draft
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("毫无困难").font(.system(size: 11, design: .serif)).foregroundStyle(Tokens.inkSoft)
                Spacer()
                Text(verbatim: "\(draft.selfControl)")
                    .font(.system(size: 22, design: .monospaced))
                    .foregroundStyle(Tokens.giltDeep)
                Spacer()
                Text("非常难").font(.system(size: 11, design: .serif)).foregroundStyle(Tokens.inkSoft)
            }
            Slider(
                value: Binding(
                    get: { Double(draft.selfControl) },
                    set: { draft.selfControl = Int($0.rounded()) }
                ),
                in: 1...7,
                step: 1
            )
            .tint(Tokens.giltDeep)
        }
    }
}

// MARK: - 枚举文案

extension Industry {
    var label: String {
        switch self {
        case .tech: return "互联网 / 科技"
        case .finance: return "金融"
        case .healthcare: return "医疗"
        case .education: return "教育"
        case .manufacturing: return "制造业"
        case .government: return "体制内"
        case .retailService: return "零售 / 服务业"
        case .creative: return "文创 / 设计"
        case .freelance: return "自由职业"
        case .other: return "其他"
        }
    }
}

extension Education {
    var label: String {
        switch self {
        case .belowBachelor: return "本科以下"
        case .bachelor: return "本科"
        case .masterPlus: return "硕士及以上"
        }
    }
}

extension TradingHabit {
    var label: String {
        switch self {
        case .indexOnly: return "不炒,只定投指数"
        case .occasional: return "偶尔买卖,一年几次"
        case .weekly: return "每周都看盘,常换手"
        case .dayTrading: return "日内交易"
        }
    }
}

extension AccountTier {
    var label: String {
        switch self {
        case .under100k: return "10 万以下"
        case .k100to500k: return "10–50 万"
        case .k500to10m: return "50 万–1000 万"
        case .over10m: return "1000 万以上"
        }
    }
}
