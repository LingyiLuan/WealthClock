import XCTest
@testable import FreedomEngine

final class GoldenTests: XCTestCase {
    struct Fixture: Decodable {
        struct Case: Decodable {
            let name: String
            let savingsRate: Double
            let realReturn: Double
            let assetsInIncomeUnits: Double
            let multiplier: Double
            let expectedYears: Double
        }
        let toleranceYears: Double
        let cases: [Case]

        enum CodingKeys: String, CodingKey {
            case toleranceYears = "tolerance_years"
            case cases
        }
    }

    private func loadFixture() throws -> Fixture {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "golden", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    /// 所有修正项中性化的基线 Profile。
    private func neutralProfile(age: Int = 30, annualIncome: Double, savingsRate: Double, assetsUnits: Double) -> Profile {
        Profile(
            age: age,
            region: .other,
            currencyCode: "USD",
            monthlyIncome: annualIncome / 12,
            monthlyExpense: annualIncome * (1 - savingsRate) / 12,
            investableAssets: annualIncome * assetsUnits,
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

    private func flatParams(realReturn: Double, multiplier: Double) -> ScenarioParams {
        ScenarioParams(
            withdrawalRate: 1.0 / multiplier,
            realReturn: realReturn,
            prePeakGrowth: 0,
            postPeakGrowth: 0,
            expenseGrowth: 0,
            peakAgeCN: 99,
            peakAgeOther: 99
        )
    }

    func testClosedFormGolden() throws {
        let fixture = try loadFixture()
        for c in fixture.cases {
            let profile = neutralProfile(annualIncome: 100_000, savingsRate: c.savingsRate, assetsUnits: c.assetsInIncomeUnits)
            let result = FreedomEngine.simulate(profile, kind: .neutral, params: flatParams(realReturn: c.realReturn, multiplier: c.multiplier))
            let age = try XCTUnwrap(result.freedomAge, "case \(c.name) returned nil")
            let years = age - Double(profile.age)
            XCTAssertEqual(years, c.expectedYears, accuracy: fixture.toleranceYears, "case \(c.name): got \(years), expected \(c.expectedYears)")
        }
    }

    func testAlreadyFreeReturnsCurrentAge() {
        var p = neutralProfile(annualIncome: 100_000, savingsRate: 0.3, assetsUnits: 50)
        p.age = 40
        let r = FreedomEngine.simulate(p, kind: .neutral)
        XCTAssertEqual(r.freedomAge, 40)
    }

    /// BRIEF §3.6(b):零增长金标条件下,储蓄为负 → 永远达不到 → nil。
    /// (真实中性参数含收入增速,储蓄可能由负转正,不属于此金标条件。)
    func testNegativeSavingsNeverReaches() {
        var p = neutralProfile(annualIncome: 100_000, savingsRate: 0.3, assetsUnits: 0)
        p.monthlyExpense = p.monthlyIncome * 1.2
        let r = FreedomEngine.simulate(p, kind: .neutral, params: flatParams(realReturn: 0.05, multiplier: 25))
        XCTAssertNil(r.freedomAge)
    }

    func testBirthDateNeverChangesOutput() {
        let a = FreedomEngine.run(Profile.sample)
        var withBirth = Profile.sample
        withBirth.birthDate = Date(timeIntervalSince1970: 0)
        let b = FreedomEngine.run(withBirth)
        XCTAssertEqual(a, b, "birthDate must not affect any calculation (AGENTS.md §7.6)")
    }

    func testDayTradingDelaysFreedom() {
        var p = Profile.sample
        p.tradingHabit = .dayTrading
        let r = FreedomEngine.run(p)
        let trading = r.attributions.first { $0.key == "trading" }
        XCTAssertNotNil(trading)
        if let d = trading?.deltaYears { XCTAssertGreaterThan(d, 0) }
    }

    func testScenariosAreOrdered() {
        let r = FreedomEngine.run(Profile.sample)
        let o = r.scenario(.optimistic)?.freedomAge
        let n = r.scenario(.neutral)?.freedomAge
        let pes = r.scenario(.pessimistic)?.freedomAge
        if let o = o, let n = n { XCTAssertLessThanOrEqual(o, n) }
        if let n = n, let pes = pes { XCTAssertLessThanOrEqual(n, pes) }
    }

    func testSuzhou() {
        XCTAssertEqual(Suzhou.string(from: 47), "〤〧")
        XCTAssertEqual(Suzhou.chineseUpper(47), "肆拾柒")
        XCTAssertEqual(Suzhou.chineseUpper(10), "拾")
    }

    func testInscription() {
        XCTAssertEqual(Suzhou.inscription(28), "廿八")
        XCTAssertEqual(Suzhou.inscription(35), "卅五")
        XCTAssertEqual(Suzhou.inscription(47), "四十七")
        XCTAssertEqual(Suzhou.inscription(20), "廿")
        XCTAssertEqual(Suzhou.inscription(10), "十")
        XCTAssertEqual(Suzhou.inscription(7), "七")
    }
}
