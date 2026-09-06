import Foundation

public enum ScenarioKind: String, Codable, CaseIterable, Equatable {
    case pessimistic, neutral, optimistic
}

/// 一组情景参数。每个数字的出处见 EngineParams.swift 与 docs/research/science-basis.md。
public struct ScenarioParams: Equatable {
    public var withdrawalRate: Double   // 安全提取率
    public var realReturn: Double       // 真实年化收益
    public var prePeakGrowth: Double    // 峰值前收入实际增速
    public var postPeakGrowth: Double   // 峰值后收入实际增速
    public var expenseGrowth: Double    // 支出实际增速
    public var peakAgeCN: Int           // 中国大陆收入峰值年龄
    public var peakAgeOther: Int        // 其他地区收入峰值年龄

    public var multiplier: Double { 1.0 / withdrawalRate }

    public init(
        withdrawalRate: Double,
        realReturn: Double,
        prePeakGrowth: Double,
        postPeakGrowth: Double,
        expenseGrowth: Double,
        peakAgeCN: Int,
        peakAgeOther: Int
    ) {
        self.withdrawalRate = withdrawalRate
        self.realReturn = realReturn
        self.prePeakGrowth = prePeakGrowth
        self.postPeakGrowth = postPeakGrowth
        self.expenseGrowth = expenseGrowth
        self.peakAgeCN = peakAgeCN
        self.peakAgeOther = peakAgeOther
    }
}

public struct ScenarioResult: Equatable {
    public let kind: ScenarioKind
    /// 自由年龄(可含小数,月级插值);nil = 100 岁前未达。
    public let freedomAge: Double?
    /// 触达时(或终止时)的自由线金额。
    public let freedomLine: Double
}

public struct Attribution: Equatable {
    /// "trading" / "sideHustle" / "literacy" / "selfControl"
    public let key: String
    /// 正数 = 该因素推迟了自由年龄的年数;nil = 无法比较(某一侧未达)。
    public let deltaYears: Double?
    /// 文献依据(短句,UI 里可展开)。
    public let basis: String
}

public struct FreedomResult: Equatable {
    public let scenarios: [ScenarioResult]
    public let attributions: [Attribution]

    public func scenario(_ kind: ScenarioKind) -> ScenarioResult? {
        scenarios.first { $0.kind == kind }
    }
}
