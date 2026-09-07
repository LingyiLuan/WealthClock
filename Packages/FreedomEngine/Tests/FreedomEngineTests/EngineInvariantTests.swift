import XCTest
@testable import FreedomEngine

/// BRIEF §3.6 金标测试补全:不变量 (c) 与储蓄率单调性。
final class EngineInvariantTests: XCTestCase {
    private func profile(savingsRate: Double, annualIncome: Double = 100_000) -> Profile {
        Profile(
            age: 30,
            region: .other,
            currencyCode: "USD",
            monthlyIncome: annualIncome / 12,
            monthlyExpense: annualIncome * (1 - savingsRate) / 12,
            investableAssets: 0,
            industry: .other,
            yearsExperience: 5,
            education: .bachelor,
            tradingHabit: .indexOnly,
            accountTier: .k100to500k,
            hasSideHustle: false,
            literacyScore: 2,
            selfControl: 3
        )
    }

    private let goldenParams = ScenarioParams(
        withdrawalRate: 0.04,
        realReturn: 0.05,
        prePeakGrowth: 0,
        postPeakGrowth: 0,
        expenseGrowth: 0,
        peakAgeCN: 99,
        peakAgeOther: 99
    )

    /// 更高储蓄率 → 自由年龄不晚于原值(零增长金标条件)。
    func testHigherSavingsRateNeverLaterFlatParams() throws {
        let rates = stride(from: 0.05, through: 0.75, by: 0.05)
        var previous = Double.infinity
        for rate in rates {
            let result = FreedomEngine.simulate(profile(savingsRate: rate), kind: .neutral, params: goldenParams)
            let age = try XCTUnwrap(result.freedomAge, "savings rate \(rate) should reach freedom before 100")
            XCTAssertLessThanOrEqual(age, previous, "savings rate \(rate): freedom age \(age) later than lower rate's \(previous)")
            previous = age
        }
    }

    /// 同一不变量在真实中性参数(含收入增速、峰值年龄)下也须成立。
    func testHigherSavingsRateNeverLaterNeutralScenario() throws {
        let rates = stride(from: 0.05, through: 0.75, by: 0.05)
        var previous = Double.infinity
        for rate in rates {
            let result = FreedomEngine.simulate(profile(savingsRate: rate), kind: .neutral)
            let age = try XCTUnwrap(result.freedomAge, "savings rate \(rate) should reach freedom before 100")
            XCTAssertLessThanOrEqual(age, previous, "savings rate \(rate): freedom age \(age) later than lower rate's \(previous)")
            previous = age
        }
    }

    /// BRIEF §3.6(c):归因每一项单独可复现——把该因素中性化重跑,差值与引擎输出一致。
    func testAttributionsIndividuallyReproducible() throws {
        var full = Profile.sample
        full.tradingHabit = .dayTrading
        full.hasSideHustle = true
        full.literacyScore = 0
        full.selfControl = 6

        let result = FreedomEngine.run(full)
        XCTAssertEqual(
            result.attributions.map(\.key),
            ["trading", "sideHustle", "literacy", "selfControl"]
        )

        let base = try XCTUnwrap(FreedomEngine.simulate(full, kind: .neutral).freedomAge)
        let neutralizations: [String: (inout Profile) -> Void] = [
            "trading": { $0.tradingHabit = .indexOnly },
            "sideHustle": { $0.hasSideHustle = false },
            "literacy": { $0.literacyScore = 2 },
            "selfControl": { $0.selfControl = 3 }
        ]
        for attribution in result.attributions {
            var alt = full
            try XCTUnwrap(neutralizations[attribution.key])(&alt)
            let altAge = try XCTUnwrap(FreedomEngine.simulate(alt, kind: .neutral).freedomAge)
            let expected = ((base - altAge) * 10).rounded() / 10
            XCTAssertEqual(attribution.deltaYears, expected, "attribution \(attribution.key) not independently reproducible")
        }
    }

    /// M1 验收产物:打印 Profile.sample 的三情景 + 归因表(engine-verification 技能要求的记录)。
    func testPrintSampleProfileReport() {
        let result = FreedomEngine.run(Profile.sample)
        XCTAssertEqual(result.scenarios.count, 3)
        var lines = ["=== Profile.sample 三情景 ==="]
        for scenario in result.scenarios {
            let ageText = scenario.freedomAge.map { String(format: "%.1f 岁", $0) } ?? "100 岁前未达"
            lines.append("\(scenario.kind.rawValue): \(ageText)  自由线 \(String(format: "%.0f", scenario.freedomLine))")
        }
        lines.append("=== 归因(中性基准,年数差)===")
        for attribution in result.attributions {
            let delta = attribution.deltaYears.map { String(format: "%+.1f 年", $0) } ?? "不可比"
            lines.append("\(attribution.key): \(delta)  依据: \(attribution.basis)")
        }
        print(lines.joined(separator: "\n"))
    }
}
