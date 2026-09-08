import Foundation
import FreedomEngine

/// 问卷步骤(BRIEF §4:12 题 + 可选出生日期;素养一题三屏)。
enum QuizStep: Hashable {
    case age, region, income, expense, assets, mortgage, industryExperience
    case education, trading, sideHustle, literacy(Int), selfControl, birthDate

    static let all: [QuizStep] = [
        .age, .region, .income, .expense, .assets, .mortgage, .industryExperience,
        .education, .trading, .sideHustle, .literacy(0), .literacy(1), .literacy(2),
        .selfControl, .birthDate
    ]

    /// 题号 1...12(素养三屏同为第 11 问);出生日期为附问 13。
    var questionNumber: Int {
        switch self {
        case .age: return 1
        case .region: return 2
        case .income: return 3
        case .expense: return 4
        case .assets: return 5
        case .mortgage: return 6
        case .industryExperience: return 7
        case .education: return 8
        case .trading: return 9
        case .sideHustle: return 10
        case .literacy: return 11
        case .selfControl: return 12
        case .birthDate: return 13
        }
    }

    var title: String {
        switch self {
        case .age: return "你今年多大?"
        case .region: return "你在哪里生活?"
        case .income: return "税后月收入是多少?"
        case .expense: return "每月花多少?(不含房贷)"
        case .assets: return "手上有多少可投资资产?"
        case .mortgage: return "有房贷吗?"
        case .industryExperience: return "做哪一行?入行几年了?"
        case .education: return "最高学历?"
        case .trading: return "你炒股吗?"
        case .sideHustle: return "有副业收入吗?"
        case .literacy(let index): return Literacy.questions[index].prompt
        case .selfControl: return "控制支出对你来说有多难?"
        case .birthDate: return "出生日期(可选)"
        }
    }

    var why: String {
        switch self {
        case .age: return "模拟从这个年龄开始,到 100 岁为止。"
        case .region: return "地区决定收入峰值年龄的参照曲线与币种。"
        case .income: return "只算到手的。年终奖平摊到月。"
        case .expense: return "自由线 = 年支出 × 25 上下。支出比收入更能决定你的自由年龄。"
        case .assets: return "不含自住房。现金、存款、基金、股票都算。"
        case .mortgage: return "月供与剩余年数。还清后它不再计入自由线。没有可跳过。"
        case .industryExperience: return "行业影响收入峰值出现的早晚。"
        case .education: return "教育回报影响峰值前的收入增速——Mincer 曲线。"
        case .trading: return "这一问会修正你的预期收益。频繁交易的散户平均跑输市场——这是有论文的,不是玄学。"
        case .sideHustle: return "有的话收入按 +10% 假设。文献证据弱,报告里会注明。"
        case .literacy: return "三道全球通用的素养题,答完立刻看对错。"
        case .selfControl: return "1 = 毫无困难,7 = 非常难。文献显示这只影响悲观情景。"
        case .birthDate: return "仅用于汇票上的密押与配色,不参与计算。"
        }
    }

    /// 可跳过的题(房贷、出生日期)。
    var skippable: Bool {
        self == .mortgage || self == .birthDate
    }
}

/// 地区选项 → Region + 币种(BRIEF §4 第 2 题:地区/币种一并选定)。
enum RegionChoice: String, CaseIterable, Identifiable {
    case cnMainland, hkTw, sea, northAmerica, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cnMainland: return "中国大陆 · CNY"
        case .hkTw: return "港澳台 · HKD"
        case .sea: return "东南亚 · SGD"
        case .northAmerica: return "北美 · USD"
        case .other: return "其他 · USD"
        }
    }

    var region: Region {
        switch self {
        case .cnMainland: return .cnMainland
        case .hkTw: return .hkTw
        case .sea: return .sea
        case .northAmerica: return .northAmerica
        case .other: return .other
        }
    }

    var currencyCode: String {
        switch self {
        case .cnMainland: return "CNY"
        case .hkTw: return "HKD"
        case .sea: return "SGD"
        case .northAmerica: return "USD"
        case .other: return "USD"
        }
    }

    var currencySymbol: String {
        self == .cnMainland ? "¥" : "$"
    }
}

/// 问卷草稿:全部输入的暂存,答完后组装 Profile(接引擎在 M5 第三个 PR)。
@Observable final class QuizDraft {
    var age = 29
    var regionChoice: RegionChoice?
    var monthlyIncome: Double?
    var monthlyExpense: Double?
    var investableAssets: Double?
    var mortgageMonthly: Double?
    var mortgageYearsLeft = 0
    var industry: Industry?
    var yearsExperience = 5
    var education: Education?
    var tradingHabit: TradingHabit?
    var accountTier: AccountTier?
    var hasSideHustle: Bool?
    var literacyAnswers: [String: Int] = [:]
    var selfControl = 4
    var birthDate: Date?

    /// 某一步是否已作答(决定能否"下一问"与落爻)。
    func isAnswered(_ step: QuizStep) -> Bool {
        switch step {
        case .age: return true
        case .region: return regionChoice != nil
        case .income: return (monthlyIncome ?? 0) > 0
        case .expense: return (monthlyExpense ?? -1) >= 0
        case .assets: return (investableAssets ?? -1) >= 0
        case .mortgage: return true
        case .industryExperience: return industry != nil
        case .education: return education != nil
        case .trading: return tradingHabit != nil && accountTier != nil
        case .sideHustle: return hasSideHustle != nil
        case .literacy(let index): return literacyAnswers[Literacy.questions[index].id] != nil
        case .selfControl: return true
        case .birthDate: return true
        }
    }

    /// 已落爻数 0...12(第 N 问全部作答即落第 N 爻;附问不落爻)。
    func yaoCount(upTo stepIndex: Int) -> Int {
        var answered = Set<Int>()
        for (index, step) in QuizStep.all.enumerated() where index < stepIndex && step.questionNumber <= 12 {
            if step.questionNumber == 11 {
                if literacyAnswers.count == Literacy.questions.count { answered.insert(11) }
            } else {
                answered.insert(step.questionNumber)
            }
        }
        return answered.count
    }
}
