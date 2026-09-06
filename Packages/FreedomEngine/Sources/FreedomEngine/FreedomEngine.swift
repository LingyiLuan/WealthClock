import Foundation

public enum FreedomEngine {
    /// 三情景 + 归因。
    public static func run(_ profile: Profile) -> FreedomResult {
        let scenarios = ScenarioKind.allCases.map { simulate(profile, kind: $0) }
        let base = simulate(profile, kind: .neutral).freedomAge

        var attributions: [Attribution] = []
        func attribute(key: String, basis: String, _ mutate: (inout Profile) -> Void) {
            var alt = profile
            mutate(&alt)
            let altAge = simulate(alt, kind: .neutral).freedomAge
            var delta: Double?
            if let b = base, let a = altAge {
                delta = ((b - a) * 10).rounded() / 10
            }
            attributions.append(Attribution(key: key, deltaYears: delta, basis: basis))
        }

        attribute(key: "trading", basis: EngineParams.Basis.trading) { $0.tradingHabit = .indexOnly }
        if profile.hasSideHustle {
            attribute(key: "sideHustle", basis: EngineParams.Basis.sideHustle) { $0.hasSideHustle = false }
        }
        attribute(key: "literacy", basis: EngineParams.Basis.literacy) { $0.literacyScore = 2 }
        attribute(key: "selfControl", basis: EngineParams.Basis.selfControl) { $0.selfControl = 3 }

        return FreedomResult(scenarios: scenarios, attributions: attributions)
    }

    public static func simulate(_ profile: Profile, kind: ScenarioKind) -> ScenarioResult {
        simulate(profile, kind: kind, params: EngineParams.scenario(kind))
    }

    /// 核心模拟。`params` 可注入,供金标测试用闭式解校验。
    static func simulate(_ profile: Profile, kind: ScenarioKind, params sp: ScenarioParams) -> ScenarioResult {
        let trading = EngineParams.tradingAdjustment(profile.tradingHabit)
        var realReturn = sp.realReturn
            + trading.delta * EngineParams.tierMultiplier(profile.accountTier)
            + EngineParams.literacyAdjustment(profile.literacyScore)
        realReturn = max(realReturn, -0.5)

        var assets = profile.investableAssets
        var income = profile.monthlyIncome * 12 * (profile.hasSideHustle ? 1 + EngineParams.sideHustleUplift : 1)
        var expense = profile.monthlyExpense * 12
        if kind == .pessimistic && profile.selfControl >= EngineParams.selfControlThreshold {
            expense *= EngineParams.selfControlExpenseFactor
        }
        let mortgage = profile.mortgageMonthly * 12
        var mortgageLeft = max(profile.mortgageYearsLeft, 0)

        let peakBase = profile.region == .cnMainland ? sp.peakAgeCN : sp.peakAgeOther
        let peakAge = peakBase + EngineParams.industryPeakAdjustment(profile.industry, region: profile.region)
        let preGrowth = sp.prePeakGrowth + EngineParams.educationGrowthAdjustment(profile.education)

        var previousGap: Double?
        var line = expense * sp.multiplier

        for age in profile.age..<EngineParams.maxAge {
            line = expense * sp.multiplier
            let gap = assets - line
            if gap >= 0 && mortgageLeft == 0 {
                if let pg = previousGap, pg < 0, gap - pg > 0 {
                    let fraction = (-pg) / (gap - pg)
                    return ScenarioResult(kind: kind, freedomAge: Double(age - 1) + fraction, freedomLine: line)
                }
                return ScenarioResult(kind: kind, freedomAge: Double(age), freedomLine: line)
            }
            previousGap = mortgageLeft == 0 ? gap : nil

            let savings = income - expense - (mortgageLeft > 0 ? mortgage : 0)
            assets = assets * (1 + realReturn) + savings
            let growth = age < peakAge ? preGrowth : sp.postPeakGrowth
            income *= (1 + growth)
            expense *= (1 + sp.expenseGrowth)
            if mortgageLeft > 0 { mortgageLeft -= 1 }
        }
        return ScenarioResult(kind: kind, freedomAge: nil, freedomLine: line)
    }
}
