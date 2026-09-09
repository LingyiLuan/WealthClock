import FreedomEngine
import XCTest
@testable import WealthClock

final class WhatIfTests: XCTestCase {
    /// 滑杆值映射为 Profile 后,与直接构造的 Profile 引擎结果一致。
    func testStateMappingMatchesDirectProfile() {
        var state = WhatIfState(from: Profile.sample)
        state.savingsRatePercent = 40
        state.tradingHabit = .indexOnly
        state.hasSideHustle = true
        state.investableAssets = 500_000

        let mapped = state.apply(to: Profile.sample)

        var direct = Profile.sample
        direct.monthlyExpense = Profile.sample.monthlyIncome * 0.6
        direct.tradingHabit = .indexOnly
        direct.hasSideHustle = true
        direct.investableAssets = 500_000

        XCTAssertEqual(mapped, direct)
        XCTAssertEqual(FreedomEngine.run(mapped), FreedomEngine.run(direct))
    }

    /// 初始状态恢复:未拉动时 apply 不改变引擎输出(恢复原始的语义)。
    func testPristineStateIsIdentity() {
        let state = WhatIfState(from: Profile.sample)
        let mapped = state.apply(to: Profile.sample)
        XCTAssertEqual(FreedomEngine.run(mapped), FreedomEngine.run(Profile.sample))
    }
}
