import FreedomEngine
import SwiftData
import XCTest
@testable import WealthClock

final class YearComparisonTests: XCTestCase {
    @MainActor
    func testComparisonAcrossOneYear() throws {
        let container = try ModelContainer(
            for: Reading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        var older = Profile.sample
        older.monthlyExpense = 19_500
        older.investableAssets = 180_000
        let previous = Reading(profile: older, result: FreedomEngine.run(older), date: Date(timeIntervalSinceNow: -370 * 86_400))
        let current = Reading(profile: .sample, result: FreedomEngine.run(.sample))
        context.insert(previous)
        context.insert(current)

        let comparison = try XCTUnwrap(YearComparison.make(current: current, among: [previous, current]))
        XCTAssertGreaterThanOrEqual(comparison.daysApart, YearComparison.minimumDaysApart)
        XCTAssertEqual(comparison.previousSavingsRate, 22)
        XCTAssertEqual(comparison.currentSavingsRate, 28)
        XCTAssertEqual(comparison.previousAssets, 180_000)
        XCTAssertEqual(comparison.currentAssets, 300_000)
        let delta = try XCTUnwrap(comparison.ageDelta)
        XCTAssertLessThan(delta, 0, "储蓄率与资产都变好,自由年龄应提前")

        // 相隔不足 300 天 → 无对比。
        let recent = Reading(profile: older, result: FreedomEngine.run(older), date: Date(timeIntervalSinceNow: -100 * 86_400))
        context.insert(recent)
        XCTAssertNil(YearComparison.make(current: current, among: [recent, current]))
    }
}
