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

// MARK: - 步进器(替代滚轮:滚轮与 ScrollView 手势冲突,整体废弃)

struct StepperRow: View {
    let title: String
    let range: ClosedRange<Int>
    let unit: String
    @Binding var value: Int

    var body: some View {
        HStack {
            Text(verbatim: title)
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Tokens.inkSoft)
            Spacer()
            HStack(spacing: 0) {
                stepButton("minus") { value = max(range.lowerBound, value - 1) }
                Text(verbatim: "\(value) \(unit)")
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundStyle(Tokens.ink)
                    .frame(minWidth: 92)
                stepButton("plus") { value = min(range.upperBound, value + 1) }
            }
            .background(.white.opacity(0.33))
            .border(Tokens.ink.opacity(0.2), width: 1)
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Tokens.giltDeep)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
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
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, _ in
                ChoiceRow(
                    label: LiteracyL10n.options(question)[index],
                    detail: detail(for: index),
                    selected: answer == index
                ) {
                    if answer == nil { draft.literacyAnswers[question.id] = index }
                }
            }
            if let answer {
                Text(verbatim: (answer == question.correctIndex ? String(localized: "答对了。") : String(localized: "不对。")) + LiteracyL10n.explanation(question))
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
                StepperRow(title: String(localized: "年龄"), range: 18...70, unit: String(localized: "岁"), value: $draft.age)
            case .region:
                ForEach(RegionChoice.allCases) { choice in
                    ChoiceRow(label: choice.label, selected: draft.regionChoice == choice) {
                        draft.regionChoice = choice
                    }
                }
            case .income:
                MoneyField(prefix: currencySymbol, placeholder: String(localized: "税后月收入"), value: $draft.monthlyIncome)
            case .expense:
                MoneyField(prefix: currencySymbol, placeholder: String(localized: "月支出"), value: $draft.monthlyExpense)
            case .assets:
                MoneyField(prefix: currencySymbol, placeholder: String(localized: "可投资资产"), value: $draft.investableAssets)
            case .mortgage:
                MoneyField(prefix: currencySymbol, placeholder: String(localized: "每月月供"), value: $draft.mortgageMonthly)
                StepperRow(title: String(localized: "剩余年数"), range: 0...40, unit: String(localized: "年"), value: $draft.mortgageYearsLeft)
            case .industryExperience:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                    ForEach(Industry.allCases, id: \.self) { industry in
                        ChoiceRow(label: industry.label, selected: draft.industry == industry) {
                            draft.industry = industry
                        }
                    }
                }
                StepperRow(title: String(localized: "工作年限"), range: 0...40, unit: String(localized: "年"), value: $draft.yearsExperience)
                    .padding(.top, 6)
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
                ChoiceRow(label: String(localized: "有"), selected: draft.hasSideHustle == true) { draft.hasSideHustle = true }
                ChoiceRow(label: String(localized: "没有"), selected: draft.hasSideHustle == false) { draft.hasSideHustle = false }
            case .literacy(let index):
                LiteracyStepView(question: Literacy.questions[index], draft: draft)
            case .selfControl:
                selfControlSlider
            case .birthDate:
                Toggle(isOn: Binding(
                    get: { draft.birthDate != nil },
                    set: { draft.birthDate = $0 ? Date(timeIntervalSince1970: 631_152_000) : nil }
                )) {
                    Text(draft.birthDate == nil ? LocalizedStringKey("不填(汇票用朱砂色系)") : LocalizedStringKey("填写出生日期"))
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
                    .datePickerStyle(.compact)  // 弹出日历,不与 ScrollView 抢手势
                    .tint(Tokens.giltDeep)
                    .font(.system(size: 13, design: .serif))
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
        case .tech: return String(localized: "互联网 / 科技")
        case .finance: return String(localized: "金融")
        case .healthcare: return String(localized: "医疗")
        case .education: return String(localized: "教育")
        case .manufacturing: return String(localized: "制造业")
        case .government: return String(localized: "体制内")
        case .retailService: return String(localized: "零售 / 服务业")
        case .creative: return String(localized: "文创 / 设计")
        case .freelance: return String(localized: "自由职业")
        case .other: return String(localized: "其他")
        }
    }
}

extension Education {
    var label: String {
        switch self {
        case .belowBachelor: return String(localized: "本科以下")
        case .bachelor: return String(localized: "本科")
        case .masterPlus: return String(localized: "硕士及以上")
        }
    }
}

extension TradingHabit {
    var label: String {
        switch self {
        case .indexOnly: return String(localized: "不炒,只定投指数")
        case .occasional: return String(localized: "偶尔买卖,一年几次")
        case .weekly: return String(localized: "每周都看盘,常换手")
        case .dayTrading: return String(localized: "日内交易")
        }
    }
}

extension AccountTier {
    var label: String {
        switch self {
        case .under100k: return String(localized: "10 万以下")
        case .k100to500k: return String(localized: "10–50 万")
        case .k500to10m: return String(localized: "50 万–1000 万")
        case .over10m: return String(localized: "1000 万以上")
        }
    }
}

// MARK: - 素养题文案本地化(题库在纯 Foundation 引擎里,翻译在 App 层按 id 映射)

enum LiteracyL10n {
    static func prompt(_ question: LiteracyQuestion) -> String {
        switch question.id {
        case "compound": return String(localized: "100 元存入年利率 2% 的账户,五年后账户里的钱会:")
        case "inflation": return String(localized: "账户年利率 1%,通胀 2%。一年后,这笔钱能买到的东西:")
        default: return String(localized: "“买单只公司的股票,通常比买一只股票基金更安全。”这句话:")
        }
    }

    static func options(_ question: LiteracyQuestion) -> [String] {
        switch question.id {
        case "compound":
            return [String(localized: "多于 102 元"), String(localized: "正好 102 元"), String(localized: "少于 102 元")]
        case "inflation":
            return [String(localized: "比今天多"), String(localized: "和今天一样"), String(localized: "比今天少")]
        default:
            return [String(localized: "对"), String(localized: "错")]
        }
    }

    static func explanation(_ question: LiteracyQuestion) -> String {
        switch question.id {
        case "compound": return String(localized: "利息会再生利息。五年后约 110.4 元,这就是复利。")
        case "inflation": return String(localized: "名义上多了 1%,物价涨了 2%,购买力反而下降约 1%。")
        default: return String(localized: "单只股票承担公司个体风险;基金分散到几十上百家,波动通常更小。")
        }
    }
}
