import Foundation

public enum Region: String, Codable, CaseIterable, Equatable {
    case cnMainland, hkTw, sea, northAmerica, other
}

public enum Industry: String, Codable, CaseIterable, Equatable {
    case tech, finance, healthcare, education, manufacturing, government, retailService, creative, freelance, other
}

public enum Education: String, Codable, CaseIterable, Equatable {
    case belowBachelor, bachelor, masterPlus
}

public enum TradingHabit: String, Codable, CaseIterable, Equatable {
    case indexOnly, occasional, weekly, dayTrading
}

public enum AccountTier: String, Codable, CaseIterable, Equatable {
    case under100k, k100to500k, k500to10m, over10m
}

/// 引擎输入。除 `birthDate` 外全部参与计算;`birthDate` 只供密押/配色层使用。
public struct Profile: Codable, Equatable {
    public var age: Int
    public var region: Region
    public var currencyCode: String
    public var monthlyIncome: Double
    public var monthlyExpense: Double
    public var investableAssets: Double
    public var mortgageMonthly: Double
    public var mortgageYearsLeft: Int
    public var industry: Industry
    public var yearsExperience: Int
    public var education: Education
    public var tradingHabit: TradingHabit
    public var accountTier: AccountTier
    public var hasSideHustle: Bool
    public var literacyScore: Int
    public var selfControl: Int
    /// 仅供 Omen 层。引擎必须忽略;有单测守护。
    public var birthDate: Date?

    public init(
        age: Int,
        region: Region,
        currencyCode: String,
        monthlyIncome: Double,
        monthlyExpense: Double,
        investableAssets: Double,
        mortgageMonthly: Double = 0,
        mortgageYearsLeft: Int = 0,
        industry: Industry,
        yearsExperience: Int,
        education: Education,
        tradingHabit: TradingHabit,
        accountTier: AccountTier,
        hasSideHustle: Bool,
        literacyScore: Int,
        selfControl: Int,
        birthDate: Date? = nil
    ) {
        self.age = age
        self.region = region
        self.currencyCode = currencyCode
        self.monthlyIncome = monthlyIncome
        self.monthlyExpense = monthlyExpense
        self.investableAssets = investableAssets
        self.mortgageMonthly = mortgageMonthly
        self.mortgageYearsLeft = mortgageYearsLeft
        self.industry = industry
        self.yearsExperience = yearsExperience
        self.education = education
        self.tradingHabit = tradingHabit
        self.accountTier = accountTier
        self.hasSideHustle = hasSideHustle
        self.literacyScore = min(max(literacyScore, 0), 3)
        self.selfControl = min(max(selfControl, 1), 7)
        self.birthDate = birthDate
    }

    /// 示例用户(设计稿里的 29 岁、储蓄率 28%)。
    public static let sample = Profile(
        age: 29,
        region: .cnMainland,
        currencyCode: "CNY",
        monthlyIncome: 25_000,
        monthlyExpense: 18_000,
        investableAssets: 300_000,
        industry: .tech,
        yearsExperience: 5,
        education: .bachelor,
        tradingHabit: .weekly,
        accountTier: .k100to500k,
        hasSideHustle: false,
        literacyScore: 2,
        selfControl: 3
    )
}
