import XCTest
@testable import WealthClock
import FreedomEngine

final class OmenTests: XCTestCase {
    /// 同一 Profile 抽取稳定:哈希基于排序键 JSON,跨调用/跨启动一致。
    func testOmenStableForSameProfile() {
        XCTAssertEqual(OmenPicker.entries.count, 30)
        let first = OmenPicker.pick(for: Profile.sample)
        let second = OmenPicker.pick(for: Profile.sample)
        XCTAssertEqual(first, second)
        XCTAssertEqual(OmenPicker.stableHash(Profile.sample), OmenPicker.stableHash(Profile.sample))
        XCTAssertTrue(OmenPicker.entries.contains(first))
    }

    func testYearGanzhi() {
        // 2026 = 丙午(甲子起 1984)。
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 1))
        XCTAssertEqual(OmenPicker.yearGanzhi(for: date ?? .now), "丙午")
    }
}
